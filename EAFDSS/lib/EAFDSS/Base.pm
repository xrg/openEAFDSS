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

use base qw ( Class::Base );

sub init {
	my($self, $config) = @_;

	if (! exists $config->{DIR}) {
		return $self->error("You need to provide the DIR to save the singatures!");
	} else {
		$self->{DIR} = $config->{DIR};
	}

	if (! exists $config->{SN}) {
		return $self->error("You need to provide the Serial Number of the device!");
	} else {
		$self->{SN} = $config->{SN};
	}

	return $self;
}

sub Sign {
        my($self)  = shift @_;
        my($fname) = shift @_;
        my($reply, $totalSigns, $dailySigns, $date, $time, $nextZ, $sign, $fullSign);

        $self->debug("Sign operation");

        if (-e $fname) {
		my($replySignDir, $deviceDir) = $self->_createSignDir();
		if ($replySignDir != 0) {
			return $self->error($replySignDir);
		}

                $self->debug(  "  Signing file [%s]", $fname);
                open(FH, $fname);
                ($reply, $totalSigns, $dailySigns, $date, $time, $nextZ, $sign) = $self->PROTO_GetSign(*FH);
                close(FH);

		if ($reply == 0) {
			$fullSign = sprintf("%s %04d %08d %s%s %s",
				$sign, $dailySigns, $totalSigns, $self->UTIL_date6ToHost($date), substr($time, 0, 4), $self->{SN});

			$self->_createFileA($fname, $deviceDir, $date, $dailySigns, $nextZ);
			$self->_createFileB($fullSign, $deviceDir, $date, $dailySigns, $nextZ);

	        	return $fullSign;
		} else {
			return $self->error($reply);
		}
        } else {
                $self->debug(  "  No such file [%s]", $fname);
		return $self->error(64+2);
        }

}

sub Status {
        my($self) = shift @_;

        $self->debug("Status operation");

	my($reply, $status1, $status2, $lastZ, $total, $daily, $signBlock, $remainDaily) = $self->PROTO_ReadSummary();
	if ($reply == 0) {
		my($statusLine) = sprintf("%s %d %d %d %d %d", $self->{SN}, $lastZ, $total, $daily, $signBlock, $remainDaily);
        	return $statusLine;
	} else {
		return $self->error($reply);
	}
}


sub GetTime {
        my($self) = shift @_;

        $self->debug("Read time operation");
	my($reply, $time) = $self->PROTO_ReadTime();
	if ($reply == 0) {
        	return $time;
	} else {
		return $self->error($reply);
	}
}

sub SetTime {
        my($self) = shift @_;
        my($time) = shift @_;

        $self->debug("Set time operation");
	my($reply) = $self->PROTO_SetTime($time);
	if ($reply == 0) {
        	return 0;
	} else {
		return $self->error($reply);
	}
}

sub Report {
        my($self) = shift @_;

	my($replySignDir, $deviceDir) = $self->_createSignDir();
	if ($replySignDir != 0) {
		return $self->error($replySignDir);
	}

	$self->_validateFilesB();
	$self->_validateFilesC();

        $self->debug("Issue Report operation");

	my($reply1) = $self->PROTO_IssueReport();
	if ($reply1 != 0) {
		return $self->error($reply1);
	}

	my($reply2, $status1, $status2, $totalSigns, $dailySigns, $date, $time, $z, $sn, $closure) = $self->PROTO_ReadClosure(0);
	$self->_createFileC($z, $deviceDir, $date, $time, $closure);

        return $z;
}

sub Info {
        my($self) = shift @_;

        $self->debug("Read Info operation");
	my($reply, $version) = $self->PROTO_VersionInfo();
	if ($reply == 0) {
        	return $version;
	} else {
		return $self->error($reply);
	}
}

sub GetHeaders {
        my($self) = shift @_;

        $self->debug("Read Headers operation");
	my($reply, @headers) = $self->PROTO_GetHeader();
	if ($reply == 0) {
		return \@headers;
	} else {
		return $self->error($reply);
	}
}

sub SetHeaders {
        my($self)    = shift @_;
        my($headers) = shift @_;

        $self->debug("Set Headers operation");
	my($reply) = $self->PROTO_SetHeader($headers);
	if ($reply == 0) {
		return 0;
	} else {
		return $self->error($reply);
	}
}

sub _createSignDir {
	my($self) = shift @_;

	my($result) = $self->_Recover();
	if ($result != 0) {
		return ($result, undef);
	}

	# Create The signs Dir
	if (! -d  $self->{DIR} ) {
		$self->debug("  Creating Base Dir [%s]", $self->{DIR});
		mkdir($self->{DIR});
	}

	my($deviceDir) = sprintf("%s/%s", $self->{DIR}, $self->{SN});
	if (! -d $deviceDir ) {
		$self->debug("  Creating Device Dir [%s]", $deviceDir);
		mkdir($deviceDir);
	}

	return (0, $deviceDir);
}

sub _Recover {
	my($self) = shift @_;
	my($reply, $status1, $status2, $lastZ, $total, $daily, $signBlock, $remainDaily);

	($reply, $status1, $status2) = $self->PROTO_GetStatus();
	if ($reply ne "0") { return $reply };

	my($busy, $fatal, $paper, $cmos, $printer, $user, $fiscal, $battery) = $self->UTIL_devStatus($status1);
	if ($cmos != 1) { return 0 };

	my($day, $signature, $recovery, $fiscalWarn, $dailyFull, $fiscalFull) = $self->UTIL_appStatus($status1);

	$self->debug("   CMOS is set, going for recovery!");

	($reply, $status1, $status2, $lastZ, $total, $daily, $signBlock, $remainDaily) = $self->PROTO_ReadSummary(0);
	if ($reply != 0) {
		$self->debug("   Aborting recovery because of ReadClosure reply [%d]", $reply);
		return $reply
	};

	my($regexA) = sprintf("%s\\d{6}%04d\\d{4}_a.txt", $self->{SN}, $lastZ + 1);
	my($deviceDir) = sprintf("%s/%s", $self->{DIR}, $self->{SN});

	opendir(DIR, $deviceDir) || die "can't opendir $deviceDir: $!";
	my(@afiles) = grep { /$regexA/ } readdir(DIR);
	closedir(DIR);

	foreach my $curA (@afiles) {
		$self->debug("          Checking [%s]", $curA);
		my($curFileA) = sprintf("%s/%s", $deviceDir, $curA);

		my($curFileB) = $curFileA;
		$curFileB =~ s/_a/_b/;

		my($curB)  = $curA; $curB =~ s/_a/_b/;
		my($curIndex) = substr($curA, 21, 4); $curIndex =~ s/^0*//;
		$self->debug("            Updating file B  [%s] -- Index [%d]", $curB, $curIndex);

		$self->debug("            Resigning file A [%s]", $curA);
		open(FH, $curFileA);

		my($reply, $totalSigns, $dailySigns, $date, $time, $nextZ, $sign) = $self->PROTO_GetSign(*FH);
		my($fullSign) = sprintf("%s %04d %08d %s%s %s", $sign, $dailySigns, $totalSigns, $self->UTIL_date6ToHost($date), substr($time, 0, 4), $self->{SN});
		close(FH);

		open(FB, ">>", $curFileB) || die "Error: $!";
		print(FB "\n" . $fullSign); 
		close(FB);
	}

	my($replyFinal, $z) = $self->Report();

	return($replyFinal);
}

sub _createFileA {
	my($self) = shift @_;
	my($fn)   = shift @_;
	my($dir)  = shift @_;
	my($date) = shift @_;
	my($ds)   = shift @_;
	my($curZ) = shift @_;

	my($fnA) = sprintf("%s/%s%s%04d%04d_a.txt", $dir, $self->{SN}, $self->UTIL_date6ToHost($date), $curZ, $ds);
	$self->debug("   Creating File A [%s]", $fnA);
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

	my($fnB) = sprintf("%s/%s%s%04d%04d_b.txt", $dir, $self->{SN}, $self->UTIL_date6ToHost($date), $curZ, $ds);
	$self->debug("   Creating File B [%s]", $fnB);
	open(FB, ">", $fnB) || die "Error: $!";
	print(FB $fullSign);
	close(FB);
}

sub _createFileC {
        my($self) = shift @_;
        my($z)    = shift @_;
        my($dir)  = shift @_;
        my($date) = shift @_;
        my($time) = shift @_;
        my($closure) = shift @_;

        my($fnC) = sprintf("%s/%s%s%s%04d_c.txt", $dir, $self->{SN}, $self->UTIL_date6ToHost($date), $self->UTIL_time6toHost($time), $closure);
        $self->debug(  "   Creating File C [%s]", $fnC);

        open(FC, ">", $fnC) || die "Error: $!";
        print(FC $z); 
        close(FC);
}


sub _validateFilesB {
        my($self) = shift @_;

        my($reply, $status1, $status2, $lastZ, $total, $daily, $signBlock, $remainDaily) = $self->PROTO_ReadSummary();
        if ($reply != 0) { return $reply};

        my($regexA) = sprintf("%s\\d{6}%04d\\d{4}_a.txt", $self->{SN}, $lastZ + 1);
        $self->debug(  "    Validating B Files for #%d Z with regex [%s]", $lastZ + 1 , $regexA);
        my($deviceDir) = sprintf("%s/%s", $self->{DIR}, $self->{SN});

        opendir(DIR, $deviceDir) || die "can't opendir $deviceDir: $!";
        my(@afiles) = grep { /$regexA/ } readdir(DIR);
        closedir(DIR);

        foreach my $curA (@afiles) {
                $self->debug(  "          Checking [%s]", $curA);
                my($curFileA) = sprintf("%s/%s", $deviceDir, $curA);

                my($curFileB) = $curFileA;
                $curFileB =~ s/_a/_b/;

                if (! -e $curFileB) { # TODO: Add size Check
                        my($curB)  = $curA; $curB =~ s/_a/_b/;
                        my($curIndex) = substr($curA, 21, 4); $curIndex =~ s/^0*//;
                        $self->debug(  "            Recreating file B [%s] -- Index [%d]", $curB, $curIndex);

                        my($replyCode, $status1, $status2, $totalSigns, $dailySigns, $date, $time, $sign, $sn, $closure) = $self->ReadSignEntry($curIndex);
                        my($fullSign) = sprintf("%s %04d %08d %s%s %s", $sign, $dailySigns, $totalSigns, $self->date6ToHost($date), substr($time, 0, 4), $self->{SN});

                        open(FB, ">",  $curFileB) || die "Error: $!";
                        print(FB $fullSign); 
                        close(FB);
                }
        }

        return;
}

sub _validateFilesC {
        my($self) = shift @_;

        my($reply, $status1, $status2, $lastZ, $total, $daily, $signBlock, $remainDaily) = $self->PROTO_ReadSummary();
        if ($reply != 0) { return $reply };

        my($curClosure, $curFileC, $matched);

        my($regexC) = sprintf("%s.*_c.txt", $self->{SN}, $lastZ + 1);
        $self->debug(  "    Validating C Files for, total of [%d]", $lastZ);
        my($deviceDir) = sprintf("%s/%s", $self->{DIR}, $self->{SN});

        opendir(DIR, $deviceDir) || die "can't opendir $deviceDir: $!";
        my(@cfiles) = grep { /$regexC/ } readdir(DIR);
        closedir(DIR);

        for ($curClosure = 1; $curClosure <= $lastZ;  $curClosure++) {
                $self->debug(  "      Searching for [%d]", $curClosure);

                $matched = 0;
                foreach (@cfiles) {
                        if (/${curClosure}_c\.txt$/) { 
                                $curFileC = $_;
                                $matched = 1;
                                last;
                        }
                }

                if ($matched) { 
                        $self->debug(  "          Keeping file C    [%s] -- Index [%d]", $curFileC, $curClosure);
                } else {
                        my($replyCode, $status1, $status2, $totalSigns, $dailySigns, $date, $time, $z, $sn, $closure) = $self->PROTO_ReadClosure($curClosure);
                        my($fnC) = sprintf("%s%s%s%04d_c.txt", $sn, $self->UTIL_date6ToHost($date), $self->UTIL_time6toHost($time), $curClosure);
                        $self->debug(  "          Recreating file C [%s] -- Index [%d]", $fnC, $curClosure);

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

sub debug {
	my($self)  = shift;
	my($flag);

	if (ref $self && defined $self->{ _DEBUG }) {
		$flag = $self->{ _DEBUG };
	} else {
		# go looking for package variable
		no strict 'refs';
		$self = ref $self || $self;
		$flag = ${"$self\::DEBUG"};
	}

	return unless $flag;

	printf(STDERR "[%s] %s\n", $self->id, sprintf(shift @_, @_));
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
