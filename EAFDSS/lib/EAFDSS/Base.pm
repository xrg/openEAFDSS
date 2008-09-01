# EAFDSS - Electronic Fiscal Signature Devices Library
#          Ειδική Ασφαλής Φορολογική Διάταξη Σήμανσης (ΕΑΦΔΣΣ)
#
# Copyright (C) 2008 Hasiotis Nikos
#
# ID: $Id: Base.pm 162 2008-05-08 18:44:54Z hasiotis $

package EAFDSS::Base;

use 5.006001;
use strict;
use warnings;
use Carp;
use Data::Dumper;

our(@ISA) = qw();
our($VERSION) = '0.10';

sub new {
	my($invocant) = shift @_;
	my($self) = bless({}, ref $invocant || $invocant);

	$self->_initVars(@_);
	$self->_Debug($self->{LEVEL}{DEBUG}, "[EAFDSS::Base]::[new]");

	return $self;
}

sub _initVars {
	my($self) = shift @_;

	%{$self->{LEVEL}} = 
	(
		ERROR   => -1,
		NORMAL  =>  0,
		INFO    =>  1,
		VERBOSE =>  2,
		DEBUG	=>  3,
		INSANE  =>  4
	);

	my(%params);
	while ( @_ ) {
		my($key) = uc(shift @_);
		$params{$key} = shift @_;
	}

	if (! exists $params{DIR}) {
		$self->_Debug($self->{LEVEL}{ERROR}, "    You need to provide the DIR to save the singatures!");
	} else {
		$self->{DIR} = $params{DIR};
	}

	if (! exists $params{SN}) {
		$self->_Debug($self->{LEVEL}{ERROR}, "    You need to provide the Serial Number of the device!");
	} else {
		$self->{SN} = $params{SN};
	}

	if (! exists $params{DEBUG}) {
		$self->{DEBUG} = $self->{LEVEL}{NORMAL};
	} else {
		$self->{DEBUG} = $params{DEBUG};
	}
}

sub Sign {
	my($self)  = shift @_;
	my($fname) = shift @_;
	my($reply, $totalSigns, $dailySigns, $date, $time, $nextZ, $sign, $fullSign);

	$self->_Debug($self->{LEVEL}{DEBUG}, "[EAFDSS::Base]::[Sign]");
	my($deviceDir) = $self->_createSignDir();

	if (-e $fname) {
		$self->_Debug($self->{LEVEL}{DEBUG}, "  Signing file [%s]", $fname);
		open(FH, $fname);
		($reply, $totalSigns, $dailySigns, $date, $time, $nextZ, $sign) = $self->GetSign(*FH);
		$fullSign = sprintf("%s %04d %08d %s%s %s",
			$sign, $dailySigns, $totalSigns, $self->date6ToHost($date), substr($time, 0, 4), $self->{SN});
		close(FH);

		$self->_createFileA($fname, $deviceDir, $date, $dailySigns, $nextZ);
		$self->_createFileB($fullSign, $deviceDir, $date, $dailySigns, $nextZ);
	} else {
		$self->_Debug($self->{LEVEL}{DEBUG}, "  No such file [%s]", $fname);
		return -1;
	}

	return($reply, $fullSign);
}

sub _createSignDir {
	my($self) = shift @_;

	$self->_Recover();

	# Create The signs Dir
	if (! -d  $self->{DIR} ) {
		$self->_Debug($self->{LEVEL}{INFO}, "  Creating Base Dir [%s]", $self->{DIR});
		mkdir($self->{DIR});
	}

	my($deviceDir) = sprintf("%s/%s", $self->{DIR}, $self->{SN});
	if (! -d $deviceDir ) {
		$self->_Debug($self->{LEVEL}{INFO}, "  Creating Device Dir [%s]", $deviceDir);
		mkdir($deviceDir);
	}

	return $deviceDir;
}

sub _createFileA {
	my($self) = shift @_;
	my($fn)   = shift @_;
	my($dir)  = shift @_;
	my($date) = shift @_;
	my($ds)   = shift @_;
	my($curZ) = shift @_;

	my($fnA) = sprintf("%s/%s%s%04d%04d_a.txt", $dir, $self->{SN}, $self->date6ToHost($date), $curZ, $ds);
	$self->_Debug($self->{LEVEL}{INFO}, "   Creating File A [%s]", $fnA);
	open(FH, $fn);
	open(FA, ">", $fnA) || die "Error: $!";
	seek(FH, 0, 0);
	while (<FH>) {
		print(FA $_);
	};
	close(FA);
	close(FH);
}

sub _createFileB {
	my($self) = shift @_;
	my($fullSign)   = shift @_;
	my($dir)  = shift @_;
	my($date) = shift @_;
	my($ds)   = shift @_;
	my($curZ) = shift @_;

	my($fnB) = sprintf("%s/%s%s%04d%04d_b.txt", $dir, $self->{SN}, $self->date6ToHost($date), $curZ, $ds);
	$self->_Debug($self->{LEVEL}{INFO}, "   Creating File B [%s]", $fnB);
	open(FB, ">", $fnB) || die "Error: $!";
	print(FB $fullSign); 
	close(FB);
}

sub Report {
	my($self) = shift @_;
	my($type) = shift @_;

	$self->_Debug($self->{LEVEL}{DEBUG}, "[EAFDSS::Base]::[Report]");
	my($deviceDir) = $self->_createSignDir();

	$self->ValidateFilesB();
	$self->ValidateFilesC();

	my($reply1) = $self->IssueReport();
	my($reply2, $status1, $status2, $totalSigns, $dailySigns, $date, $time, $z, $sn, $closure) = $self->ReadClosure(0);
	$self->_createFileC($z, $deviceDir, $date, $time, $closure);

	return($reply2, $z);
}

sub _Recover {
	my($self) = shift @_;
	my($reply, $status1, $status2, $lastZ, $total, $daily, $signBlock, $remainDaily);

	($reply, $status1, $status2) = $self->GetStatus();
	if ($reply != 0) { return $reply};

	my($busy, $fatal, $paper, $cmos, $printer, $user, $fiscal, $battery) = $self->devStatus($status1);
	if ($cmos != 1) { return };

	my($day, $signature, $recovery, $fiscalWarn, $dailyFull, $fiscalFull) = $self->appStatus($status1);

	$self->_Debug($self->{LEVEL}{INFO}, "   CMOS is set, going for recovery!");

	($reply, $status1, $status2, $lastZ, $total, $daily, $signBlock, $remainDaily) = $self->ReadSummary(0);
	if ($reply != 0) {
		$self->_Debug($self->{LEVEL}{INFO}, "   Aborting recovery because of ReadClosure reply [%d]", $reply);
		return $reply
	};

	my($regexA) = sprintf("%s\\d{6}%04d\\d{4}_a.txt", $self->{SN}, $lastZ + 1);
	my($deviceDir) = sprintf("%s/%s", $self->{DIR}, $self->{SN});

	opendir(DIR, $deviceDir) || die "can't opendir $deviceDir: $!";
	my(@afiles) = grep { /$regexA/ } readdir(DIR);
	closedir(DIR);

	foreach my $curA (@afiles) {
		$self->_Debug($self->{LEVEL}{INFO}, "          Checking [%s]", $curA);
		my($curFileA) = sprintf("%s/%s", $deviceDir, $curA);

		my($curFileB) = $curFileA;
		$curFileB =~ s/_a/_b/;

		my($curB)  = $curA; $curB =~ s/_a/_b/;
		my($curIndex) = substr($curA, 21, 4); $curIndex =~ s/^0*//;
		$self->_Debug($self->{LEVEL}{INFO}, "            Updating file B  [%s] -- Index [%d]", $curB, $curIndex);

		$self->_Debug($self->{LEVEL}{INFO}, "            Resigning file A [%s]", $curA);
		open(FH, $curFileA);

		my($reply, $totalSigns, $dailySigns, $date, $time, $nextZ, $sign) = $self->GetSign(*FH);
		my($fullSign) = sprintf("%s %04d %08d %s%s %s", $sign, $dailySigns, $totalSigns, $self->date6ToHost($date), substr($time, 0, 4), $self->{SN});
		close(FH);

		open(FB, ">>", $curFileB) || die "Error: $!";
		print(FB "\n" . $fullSign); 
		close(FB);
	}

	my($reply, $z) = $self->Report();
	return($reply, $z);
}

sub _createFileC {
	my($self) = shift @_;
	my($z)    = shift @_;
	my($dir)  = shift @_;
	my($date) = shift @_;
	my($time) = shift @_;
	my($closure) = shift @_;

	my($fnC) = sprintf("%s/%s%s%s%04d_c.txt", $dir, $self->{SN}, $self->date6ToHost($date), $self->time6toHost($time), $closure);
	$self->_Debug($self->{LEVEL}{INFO}, "   Creating File C [%s]", $fnC);

	open(FC, ">", $fnC) || die "Error: $!";
	print(FC $z); 
	close(FC);
}

sub ValidateFilesB {
	my($self) = shift @_;

	my($reply, $status1, $status2, $lastZ, $total, $daily, $signBlock, $remainDaily) = $self->ReadSummary();
	if ($reply != 0) { return $reply};

	my($regexA) = sprintf("%s\\d{6}%04d\\d{4}_a.txt", $self->{SN}, $lastZ + 1);
	$self->_Debug($self->{LEVEL}{INFO}, "    Validating B Files for #%d Z with regex [%s]", $lastZ + 1 , $regexA);
	my($deviceDir) = sprintf("%s/%s", $self->{DIR}, $self->{SN});

	opendir(DIR, $deviceDir) || die "can't opendir $deviceDir: $!";
	my(@afiles) = grep { /$regexA/ } readdir(DIR);
	closedir(DIR);

	foreach my $curA (@afiles) {
		$self->_Debug($self->{LEVEL}{INFO}, "          Checking [%s]", $curA);
		my($curFileA) = sprintf("%s/%s", $deviceDir, $curA);

		my($curFileB) = $curFileA;
		$curFileB =~ s/_a/_b/;

		if (! -e $curFileB) { # TODO: Add size Check
			my($curB)  = $curA; $curB =~ s/_a/_b/;
			my($curIndex) = substr($curA, 21, 4); $curIndex =~ s/^0*//;
			$self->_Debug($self->{LEVEL}{INFO}, "            Recreating file B [%s] -- Index [%d]", $curB, $curIndex);

			my($replyCode, $status1, $status2, $totalSigns, $dailySigns, $date, $time, $sign, $sn, $closure) = $self->ReadSignEntry($curIndex);
			my($fullSign) = sprintf("%s %04d %08d %s%s %s", $sign, $dailySigns, $totalSigns, $self->date6ToHost($date), substr($time, 0, 4), $self->{SN});

			open(FB, ">",  $curFileB) || die "Error: $!";
			print(FB $fullSign); 
			close(FB);
		}
	}

	return;
}

sub ValidateFilesC {
	my($self) = shift @_;

	my($reply, $status1, $status2, $lastZ, $total, $daily, $signBlock, $remainDaily) = $self->ReadSummary();
	if ($reply != 0) { return $reply };

	my($curClosure, $curFileC, $matched);

	my($regexC) = sprintf("%s.*_c.txt", $self->{SN}, $lastZ + 1);
	$self->_Debug($self->{LEVEL}{INFO}, "    Validating C Files for, total of [%d]", $lastZ);
	my($deviceDir) = sprintf("%s/%s", $self->{DIR}, $self->{SN});

	opendir(DIR, $deviceDir) || die "can't opendir $deviceDir: $!";
	my(@cfiles) = grep { /$regexC/ } readdir(DIR);
	closedir(DIR);

	for ($curClosure = 1; $curClosure <= $lastZ;  $curClosure++) {
		$self->_Debug($self->{LEVEL}{INFO}, "      Searching for [%d]", $curClosure);

		$matched = 0;
		foreach (@cfiles) {
			if (/${curClosure}_c\.txt$/) { 
				$curFileC = $_;
				$matched = 1;
				last;
			}
		}

		if ($matched) { 
			$self->_Debug($self->{LEVEL}{INFO}, "          Keeping file C    [%s] -- Index [%d]", $curFileC, $curClosure);
		} else {
			my($replyCode, $status1, $status2, $totalSigns, $dailySigns, $date, $time, $z, $sn, $closure) = $self->ReadClosure($curClosure);
			my($fnC) = sprintf("%s%s%s%04d_c.txt", $sn, $self->date6ToHost($date), $self->time6toHost($time), $curClosure);
			$self->_Debug($self->{LEVEL}{INFO}, "          Recreating file C [%s] -- Index [%d]", $fnC, $curClosure);

			open(FC, ">", $deviceDir . "/" . $fnC) || die "Error: $!";
			print(FC $z); 
			close(FC);
		}
	}
}

sub DESTROY {
	my($self) = shift;
	#printfv("Destroying %s %s",  $self, $self->name );
}

sub _Debug {
	my($self) = shift @_;
	my($lvl)  = shift @_;

	if ($self->{LEVEL}{ERROR} == $lvl) {
		croak(sprintf(shift @_, @_));
	}

	if ($self->{DEBUG} >= $lvl) {
		printf("%s\n", sprintf(shift @_, @_));
	}
}

# Preloaded methods go here.

1;
__END__

=head1 NAME

EAFDSS::Base - base class for all other classes

=head1 DESCRIPTION

Nothing to describe nor to document here. Read EAFDSS::SDNP on how to use the module.

=head1 VERSION

This is version 0.10.

=head1 AUTHOR

Hasiotis Nikos, E<lt>hasiotis@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Hasiotis Nikos

This library is free software; you can redistribute it and/or modify
it under the terms of the LGPL or the same terms as Perl itself,
either Perl version 5.8.8 or, at your option, any later version of
Perl 5 you may have available.

=cut
