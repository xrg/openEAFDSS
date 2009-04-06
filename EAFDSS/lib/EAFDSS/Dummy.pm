# EAFDSS - Electronic Fiscal Signature Devices Library
#          Ειδική Ασφαλής Φορολογική Διάταξη Σήμανσης (ΕΑΦΔΣΣ)
#
# Copyright (C) 2008 Hasiotis Nikos
#
# ID: $Id$

package EAFDSS::Dummy;

=head1 NAME

EAFDSS::Dummy - EAFDSS Driver for a Dummy filesystem based device 

=head1 DESCRIPTION

Read EAFDSS on how to use the module.

=cut

use 5.6.0;
use strict;
use warnings;
use Carp;
use Class::Base;
use Switch;
use Digest::SHA1  qw(sha1_hex);
use Config::IniFiles;

use base qw ( EAFDSS::Base );

our($VERSION) = '0.40';

=head1 Methods

=head2 init

init

=cut

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
		print(DUMMY "MAX_SIGNS  = 2400\n");
		print(DUMMY "CUR_FISCAL = 1\n");
		print(DUMMY "CUR_SIGN   = 1\n");
		print(DUMMY "TOTAL_SIGN = 1\n\n");
		print(DUMMY "[FISCAL]\n\n");
		print(DUMMY "[SIGNS]\n");
		close(DUMMY);
	}

	return $self;
}

=head1 Methods

=head2 PROTO_GetSign

PROTO_GetSign  

=cut

sub PROTO_GetSign {
	my($self)    = shift @_;
	my($invoice) = shift @_;

	my($replyCode, $totalSigns, $dailySigns, $date, $time, $sign, $nextZ, $maxFiscal, $maxSigns);

	$self->debug("  [PROTO] Get Sign");

	my($sec, $min, $hour, $mday, $mon, $year) = localtime();
	$date = sprintf("%02d%02d%02d", $mday, $mon+1, $year - 100); 
	$time = sprintf("%02d%02d%02d", $hour, $min, $sec);

	my($dummy) = Config::IniFiles->new(-file => $self->{FILENAME});

	$totalSigns = $dummy->val('MAIN', 'TOTAL_SIGN');
	$dailySigns = $dummy->val('MAIN', 'CUR_SIGN');
	$nextZ      = $dummy->val('MAIN', 'CUR_FISCAL');

	$maxFiscal  = $dummy->val('MAIN', 'MAX_FISCAL');
	$maxSigns   = $dummy->val('MAIN', 'MAX_SIGNS');

	if ($dailySigns >= $maxSigns) {
		return (-1);
	}

	$dummy->newval('MAIN', 'TOTAL_SIGN', $totalSigns + 1);
	$dummy->newval('MAIN', 'CUR_SIGN', $dailySigns + 1);

	$invoice .= sprintf("%s%08d%04d%s%s", $self->{SN}, $totalSigns, $dailySigns, $self->UTIL_date6ToHost($date), $self->UTIL_time6toHost($time));

	$sign = uc(sha1_hex($invoice));
	$dummy->newval('SIGNS', $dailySigns,  $sign);

	$dummy->RewriteConfig();

	return (0, $totalSigns, $dailySigns, $date, $time, $nextZ, $sign);
}

=head2 PROTO_SetHeader

PROTO_SetHeader

=cut

sub PROTO_SetHeader {
	my($self)    = shift @_;
	my($headers) = shift @_;

	$self->debug("  [PROTO] Set Headers");
	return 64+04;
}

=head2 PROTO_GetStatus

PROTO_GetStatus

=cut

sub PROTO_GetStatus {
	my($self) = shift @_;

	$self->debug("  [PROTO] Get Status");
	if (-e $self->{FILENAME}) {
		return (0, 0, 0);
	} else {
		return ($self->error());
	}
}

=head2 PROTO_GetHeader

PROTO_GetHeader

=cut

sub PROTO_GetHeader {
	my($self) = shift @_;

	$self->debug("  [PROTO] Get Headers");
	return 64+04;
}

=head2 PROTO_ReadTime

PROTO_ReadTime

=cut

sub PROTO_ReadTime {
	my($self) = shift @_;

	$self->debug("  [PROTO] Read Time");
	my($sec, $min, $hour, $mday, $mon, $year) = localtime();
	return (0, sprintf("%02d/%02d/%02d %02d:%02d:%02d", $mday, $mon+1, $year-100, $hour, $min, $sec));
}

=head2 PROTO_SetTime

PROTO_SetTime

=cut

sub PROTO_SetTime {
	my($self) = shift @_;
	my($time) = shift @_;

	$self->debug("  [PROTO] Set Time");
	return 64+04;
}

=head2 PROTO_ReadDeviceID

PROTO_ReadDeviceID

=cut

sub PROTO_ReadDeviceID {
	my($self) = shift @_;

	$self->debug("  [PROTO] Read Device ID");
	my($dummy) = Config::IniFiles->new(-file => $self->{FILENAME});

	if ($dummy) {
		my($deviceId) = $dummy->val('MAIN', 'SERIAL');
		return (0, $deviceId);
	} else {
		return (-1);
	}
}

=head2 PROTO_VersionInfo

PROTO_VersionInfo

=cut

sub PROTO_VersionInfo {
	my($self) = shift @_;

	$self->debug("  [PROTO] Read Device Version");
	my($dummy) = Config::IniFiles->new(-file => $self->{FILENAME});

	if ($dummy) {
		my($version) = $dummy->val('MAIN', 'VERSION');
		return (0, $version);
	} else {
		return (-1);
	}
}

=head2 PROTO_ReadSignEntry

PROTO_ReadSignEntry

=cut

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

=head2 PROTO_ReadClosure

PROTO_ReadClosure

=cut

sub PROTO_ReadClosure {
	my($self)  = shift @_;
	my($index) = shift @_;
	my(%reply, $replyCode, $status1, $status2, $totalSigns, $dailySigns, $date, $time, $z, $sn, $closure, $curZ);

	$self->debug("  [PROTO] Read Closure [%d]", $index);
	my($dummy) = Config::IniFiles->new(-file => $self->{FILENAME});

	my($sec, $min, $hour, $mday, $mon, $year) = localtime();
	$date = sprintf("%02d%02d%02d", $mday, $mon+1, $year - 100); 
	$time = sprintf("%02d%02d%02d", $hour, $min, $sec);

	$totalSigns = $dummy->val('MAIN', 'TOTAL_SIGN');
	$dailySigns = $dummy->val('MAIN', 'CUR_SIGN');
	$curZ       = $dummy->val('MAIN', 'CUR_FISCAL');

	if ($index == 0) {
		$z = $dummy->val('FISCAL', $curZ-1);
	} else {
		$z = $dummy->val('FISCAL', $index);
	}
	$closure    = $curZ-1;

	return (0, 1, 1, $totalSigns, $dailySigns, $self->UTIL_date6ToHost($date), $self->UTIL_time6toHost($time), $z, $self->{SN}, $closure);
}

=head2 PROTO_ReadSummary

PROTO_ReadSummary

=cut

sub PROTO_ReadSummary {
	my($self)  = shift @_;
	my(%reply, $replyCode, $status1, $status2, $lastZ, $totalSigns, $dailySigns, $maxSigns);

	$self->debug("  [PROTO] Read Summary");
	my($dummy) = Config::IniFiles->new(-file => $self->{FILENAME});

	$totalSigns = $dummy->val('MAIN', 'TOTAL_SIGN');
	$dailySigns = $dummy->val('MAIN', 'CUR_SIGN');
	$lastZ      = $dummy->val('MAIN', 'CUR_FISCAL');

	$maxSigns   = $dummy->val('MAIN', 'MAX_SIGNS');

	return (0, 0, 0, $lastZ-1, $totalSigns-1, $dailySigns-1, 0, $maxSigns - $dailySigns + 1);
}

=head2 PROTO_IssueReport

PROTO_IssueReport

=cut

sub PROTO_IssueReport {
	my($self)  = shift @_;
	my(%reply, $replyCode, $status1, $status2, $dailySigns, $lastZ, $i, $z, $data, $time, $date, $totalSigns);

	$self->debug("  [PROTO] Issue Report");
	my($dummy) = Config::IniFiles->new(-file => $self->{FILENAME});

	my($sec, $min, $hour, $mday, $mon, $year) = localtime();
	$date = sprintf("%02d%02d%02d", $mday, $mon+1, $year - 100); 
	$time = sprintf("%02d%02d%02d", $hour, $min, $sec);

	$totalSigns = $dummy->val('MAIN', 'TOTAL_SIGN');
	$dailySigns = $dummy->val('MAIN', 'CUR_SIGN');
	$lastZ      = $dummy->val('MAIN', 'CUR_FISCAL');

	$dummy->newval('MAIN', 'CUR_FISCAL', $dummy->val('MAIN', 'CUR_FISCAL') + 1);

	$data = "";
	for ($i=1; $i < $dummy->val('MAIN', 'CUR_SIGN'); $i++) {
		$data .= $dummy->val('SIGNS', $i);
	}

	$z = uc(sha1_hex($data));

	for ($i=1; $i < $dummy->val('MAIN', 'CUR_SIGN'); $i++) {
		$dummy->delval('SIGNS', $i);
	}

	$dummy->newval('FISCAL', $lastZ, $z);
	$dummy->newval('MAIN', 'CUR_SIGN', 1);

	$dummy->RewriteConfig();

	return (0);
}

=head2 errMessage

errMessage

=cut

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

=head2 UTIL_devStatus

UTIL_devStatus

=cut

sub UTIL_devStatus {
	my($self)   = shift @_;
	my($status) = sprintf("%08b", shift);
	my(@status) = split(//, $status);

	my($busy, $fatal, $paper, $cmos, $printer, $user, $fiscal, $battery) = 
		($status[7],$status[6],$status[5],$status[4],$status[3],$status[2],$status[1],$status[0]);

	return ($busy, $fatal, $paper, $cmos, $printer, $user, $fiscal, $battery);
}

=head2 UTIL_appStatus

UTIL_appStatus

=cut

sub UTIL_appStatus {
	my($self)   = shift @_;

	my($status) = sprintf("%08b", shift);
	my(@status) = split(//, $status);

	my($day, $signature, $recovery, $fiscalWarn, $dailyFull, $fiscalFull) =
		($status[6],$status[5],$status[4],$status[2],$status[1],$status[0]);

	return ($day, $signature, $recovery, $fiscalWarn, $dailyFull, $fiscalFull);
}

=head2 UTIL_date6ToHost

UTIL_date6ToHost

=cut

sub UTIL_date6ToHost {
	my($self) = shift @_;
	my($var) = shift @_;

	$var =~ s/(\d\d)(\d\d)(\d\d)/$3$2$1/;

	return $var;
}

=head2 UTIL_time6toHost

UTIL_time6toHost

=cut

sub UTIL_time6toHost {
	my($self) = shift @_;
	my($var) = shift @_;

	$var =~ s/(\d\d)(\d\d)(\d\d)/$1$2/;

	return $var;
}

# Preloaded methods go here.

1;

=head1 VERSION

This is version 0.40.

=head1 AUTHOR

Hasiotis Nikos, E<lt>hasiotis@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Hasiotis Nikos

This library is free software; you can redistribute it and/or modify
it under the terms of the LGPL or the same terms as Perl itself,
either Perl version 5.8.8 or, at your option, any later version of
Perl 5 you may have available.

=cut
