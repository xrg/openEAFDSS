# EAFDSS - Electronic Fiscal Signature Devices Library
#          Ειδική Ασφαλής Φορολογική Διάταξη Σήμανσης (ΕΑΦΔΣΣ)
#
# Copyright (C) 2008 Hasiotis Nikos
#
# ID: $Id$

package EAFDSS::Dummy;

use 5.006001;
use strict;
use warnings;
use Carp;
use Switch;
use Digest::SHA1  qw(sha1_hex);
use Config::IniHash;
use Data::Dumper;

use base qw ( EAFDSS::Base );

sub init {
	my($class)  = shift @_;
	my($config) = @_;
	my($self)   = $class->SUPER::init(@_);

	$self->debug("  [PROTO] Initializing");

	if (! exists $config->{PARAMS}) {
		return $self->error("No parameters have been given!");
	} else {
		$self->{FILENAME} = $config->{PARAMS};
	}

	if ( ! -e $self->{FILENAME} ) {
		open(DUMMY, ">", $self->{FILENAME}) || croak "Error: $!";
		print(DUMMY "[MAIN]\n");
		print(DUMMY "VERSION    = Dummy EAFDSS\n");
		print(DUMMY "SERIAL     = $self->{SN}\n");
		print(DUMMY "MAX_FISCAL = 100\n");
		print(DUMMY "MAX_SIGNS  = 1000\n");
		print(DUMMY "CUR_FISCAL = 1\n");
		print(DUMMY "CUR_SIGN   = 1\n");
		print(DUMMY "TOTAL_SIGN = 1\n\n");
		print(DUMMY "[FISCAL]\n\n");
		print(DUMMY "[SIGNS]\n");
		close(DUMMY);
	}

	return $self;
}

sub PROTO_GetSign {
	my($self) = shift @_;
	my($fh)   = shift @_;

	my($replyCode, $totalSigns, $dailySigns, $date, $time, $sign, $nextZ, $maxFiscal, $maxSigns);

	$self->debug("  [PROTO] Get Sign");

	my($data, $chunk) = ("", "");
	while (read($fh, $chunk, 400)) {
		$data .= $chunk;
	}

	my($sec, $min, $hour, $mday, $mon, $year) = localtime();
	$date = sprintf("%02d%02d%02d", $mday, $mon+1, $year - 100); 
	$time = sprintf("%02d%02d%02d", $hour, $min, $sec);

	my($dummy) = ReadINI($self->{FILENAME}, 'case' => 'toupper');

	$totalSigns = $dummy->{MAIN}->{TOTAL_SIGN};
	$dailySigns = $dummy->{MAIN}->{CUR_SIGN};
	$nextZ      = $dummy->{MAIN}->{CUR_FISCAL};

	$maxFiscal  = $dummy->{MAIN}->{MAX_FISCAL};
	$maxSigns   = $dummy->{MAIN}->{MAX_SIGNS};

	if ($dailySigns >= $maxSigns) {
		return (-1);
	}

	$dummy->{MAIN}->{TOTAL_SIGN} = $totalSigns + 1;
	$dummy->{MAIN}->{CUR_SIGN}   = $dailySigns + 1;

	$data .= sprintf("%s%08d%04d%s%s", $self->{SN}, $totalSigns, $dailySigns, $self->UTIL_date6ToHost($date), $self->UTIL_time6toHost($time));

	$sign = uc(sha1_hex($data));
	$dummy->{SIGNS}->{$dailySigns} = $sign;

  	WriteINI($self->{FILENAME}, $dummy);

	return (0, $totalSigns, $dailySigns, $date, $time, $nextZ, $sign);
}

sub PROTO_SetHeader {
	my($self)    = shift @_;
	my($headers) = shift @_;

	$self->debug("  [PROTO] Set Headers");
	return 64+04;
}

sub PROTO_GetStatus {
	my($self) = shift @_;

	$self->debug("  [PROTO] Get Status");
	if (-e $self->{FILENAME}) {
		return (0, 0, 0);
	} else {
		return ($self->error());
	}
}

sub PROTO_GetHeader {
	my($self) = shift @_;

	$self->debug("  [PROTO] Get Headers");
	return 64+04;
}

sub PROTO_ReadTime {
	my($self) = shift @_;

	$self->debug("  [PROTO] Read Time");
	my($sec, $min, $hour, $mday, $mon, $year) = localtime();
	return (0, sprintf("%02d/%02d/%02d %02d:%02d:%02d", $mday, $mon+1, $year-100, $hour, $min, $sec));
}

sub PROTO_SetTime {
	my($self) = shift @_;
	my($time) = shift @_;

	$self->debug("  [PROTO] Set Time");
	return 64+04;
}

sub PROTO_ReadDeviceID {
	my($self) = shift @_;

	$self->debug("  [PROTO] Read Device ID");
	my($dummy) = ReadINI($self->{FILENAME});

	if ($dummy) {
		my($deviceId) = $dummy->{MAIN}->{SERIAL};
		return (0, $deviceId);
	} else {
		return (-1);
	}
}

sub PROTO_VersionInfo {
	my($self) = shift @_;

	$self->debug("  [PROTO] Read Device Version");
	my($dummy) = ReadINI($self->{FILENAME});

	if ($dummy) {
		my($version) = $dummy->{MAIN}->{VERSION};
		return (0, $version);
	} else {
		return (-1);
	}
}

sub PROTO_ReadSignEntry {
	my($self)  = shift @_;
	my($index) = shift @_;

	$self->debug("  [PROTO] Read Sign Entry");
	my(%reply) = $self->SendRequest(0x21, 0x00, "\$/$index");

	if (%reply) {
		my($replyCode, $status1, $status2, $totalSigns, $dailySigns, $date, $time, $sign, $sn, $closure) = split(/\//, $reply{DATA});
		return (hex($replyCode), $status1, $status2, $totalSigns, $dailySigns, $date, $time, $sign, $sn, $closure);
	} else {
		return (-1);
	}
}

sub PROTO_ReadClosure {
	my($self)  = shift @_;
	my($index) = shift @_;
	my(%reply, $replyCode, $status1, $status2, $totalSigns, $dailySigns, $date, $time, $z, $sn, $closure, $curZ);

	$self->debug("  [PROTO] Read Closure [%d]", $index);
	my($dummy) = ReadINI($self->{FILENAME}, 'case' => 'toupper');

	my($sec, $min, $hour, $mday, $mon, $year) = localtime();
	$date = sprintf("%02d%02d%02d", $mday, $mon+1, $year - 100); 
	$time = sprintf("%02d%02d%02d", $hour, $min, $sec);

	$totalSigns = $dummy->{MAIN}->{TOTAL_SIGN};
	$dailySigns = $dummy->{MAIN}->{CUR_SIGN};
	$curZ       = $dummy->{MAIN}->{CUR_FISCAL};

	if ($index == 0) {
		$z = $dummy->{FISCAL}->{$curZ-1};
	} else {
		$z = $dummy->{FISCAL}->{$index};
	}
	$closure    = $curZ-1;

	return (0, 1, 1, $totalSigns, $dailySigns, $self->UTIL_date6ToHost($date), $self->UTIL_time6toHost($time), $z, $self->{SN}, $closure);
}

sub PROTO_ReadSummary {
	my($self)  = shift @_;
	my(%reply, $replyCode, $status1, $status2, $lastZ, $totalSigns, $dailySigns, $maxSigns);

	$self->debug("  [PROTO] Read Summary");
	my($dummy) = ReadINI($self->{FILENAME}, 'case' => 'toupper');

	$totalSigns = $dummy->{MAIN}->{TOTAL_SIGN};
	$dailySigns = $dummy->{MAIN}->{CUR_SIGN};
	$lastZ      = $dummy->{MAIN}->{CUR_FISCAL};

	$maxSigns   = $dummy->{MAIN}->{MAX_SIGNS};

	return (0, $status1, $status2, $lastZ-1, $totalSigns, $dailySigns, 0, $maxSigns - $dailySigns);
}

sub PROTO_IssueReport {
	my($self)  = shift @_;
	my(%reply, $replyCode, $status1, $status2, $dailySigns, $lastZ, $i, $z, $data, $time, $date, $totalSigns);

	$self->debug("  [PROTO] Issue Report");
	my($dummy) = ReadINI($self->{FILENAME}, 'case' => 'toupper');

	my($sec, $min, $hour, $mday, $mon, $year) = localtime();
	$date = sprintf("%02d%02d%02d", $mday, $mon+1, $year - 100); 
	$time = sprintf("%02d%02d%02d", $hour, $min, $sec);

	$totalSigns = $dummy->{MAIN}->{TOTAL_SIGN};
	$dailySigns = $dummy->{MAIN}->{CUR_SIGN};
	$lastZ      = $dummy->{MAIN}->{CUR_FISCAL};

	$dummy->{MAIN}->{CUR_FISCAL} = $dummy->{MAIN}->{CUR_FISCAL} + 1;

	$data = "";
	for ($i=1; $i < $dummy->{MAIN}->{CUR_SIGN}; $i++) {
		print "  S > " . $dummy->{SIGNS}->{$i} . "\n";
		$data .= $dummy->{SIGNS}->{$i};
	}
	for ($i=1; $i < $dummy->{MAIN}->{CUR_FISCAL} - 1; $i++) {
		print "  F > " . $dummy->{FISCAL}->{$i} . "\n";
		$data .= $dummy->{FISCAL}->{$i};
	}
	printf("  --> %s\n", $data);

	$z = uc(sha1_hex($data));
	$dummy->{FISCAL}->{$lastZ} = $z;
	$dummy->{MAIN}->{CUR_SIGN} = 1;

  	WriteINI($self->{FILENAME}, $dummy);

	return (0);
}

sub errMessage {
	my($self)    = shift @_;
	my($errCode) = shift @_;

	switch ($errCode) {
		case 00+0x00	 { return "No errors - success"}

		case 00+0x01	 { return "Wrong number of fields"}
		case 00+0x02	 { return "Field too long"}
		case 00+0x03	 { return "Field too small"}
		case 00+0x04	 { return "Field fixed size mismatch"}
		case 00+0x05	 { return "Field range or type check failed"}
		case 00+0x06	 { return "Bad request code"}
		case 00+0x09	 { return "Printing type bad"}
		case 00+0x0A	 { return "Cannot execute with day open"}
		case 00+0x0B	 { return "RTC programming requires jumper"}
		case 00+0x0C	 { return "RTC date or time invalid"}
		case 00+0x0D	 { return "No records in fiscal period"}
		case 00+0x0E	 { return "Device is busy in another task"}
		case 00+0x0F	 { return "No more header records allowed"}
		case 00+0x10	 { return "Cannot execute with block open"}
		case 00+0x11	 { return "Block not open"}
		case 00+0x12	 { return "Bad data stream"}
		case 00+0x13	 { return "Bad signature field"}
		case 00+0x14	 { return "Z closure time limit"}
		case 00+0x15	 { return "Z closure not found"}
		case 00+0x16	 { return "Z closure record bad"}
		case 00+0x17	 { return "User browsing in progress"}
		case 00+0x18	 { return "Signature daily limit reached"}
		case 00+0x19	 { return "Printer paper end detected"}
		case 00+0x1A	 { return "Printer is offline"}
		case 00+0x1B	 { return "Fiscal unit is offline"}
		case 00+0x1C	 { return "Fatal hardware error"}
		case 00+0x1D	 { return "Fiscal unit is full"}
		case 00+0x1E	 { return "No data passed for signature"}
		case 00+0x1F	 { return "Signature does not exist"}
		case 00+0x20	 { return "Battery fault detected"}
		case 00+0x21	 { return "Recovery in progress"}
		case 00+0x22	 { return "Recovery only after CMOS reset"}
		case 00+0x23	 { return "Real-Time Clock needs programming"}
		case 00+0x24	 { return "Z closure date warning"}
		case 00+0x25	 { return "Bad character in stream"}
		case 00+0x26	 { return ""}
		case 00+0x01	 { return "Device not accessible"}

		case 64+0x01	 { return "Device not accessible"}
		case 64+0x02	 { return "No such file"}
		case 64+0x03	 { return "Device Sync Failed"}
		case 64+0x04	 { return "Function not supported"}

		else		 { return undef}
	}
}

sub UTIL_devStatus {
	my($self)   = shift @_;
	my($status) = sprintf("%08b", shift);
	my(@status) = split(//, $status);

	my($busy, $fatal, $paper, $cmos, $printer, $user, $fiscal, $battery) = 
		($status[7],$status[6],$status[5],$status[4],$status[3],$status[2],$status[1],$status[0]);

	return ($busy, $fatal, $paper, $cmos, $printer, $user, $fiscal, $battery);
}

sub UTIL_appStatus {
	my($self)   = shift @_;

	my($status) = sprintf("%08b", shift);
	my(@status) = split(//, $status);

	my($day, $signature, $recovery, $fiscalWarn, $dailyFull, $fiscalFull) =
		($status[6],$status[5],$status[4],$status[2],$status[1],$status[0]);

	return ($day, $signature, $recovery, $fiscalWarn, $dailyFull, $fiscalFull);
}

sub UTIL_date6ToHost {
	my($self) = shift @_;
	my($var) = shift @_;

	$var =~ s/(\d\d)(\d\d)(\d\d)/$3$2$1/;

	return $var;
}

sub UTIL_time6toHost {
	my($self) = shift @_;
	my($var) = shift @_;

	$var =~ s/(\d\d)(\d\d)(\d\d)/$1$2/;

	return $var;
}

# Preloaded methods go here.

1;
=head1 NAME

EAFDSS::Micrelec - base class for all other Micrelec classes

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
