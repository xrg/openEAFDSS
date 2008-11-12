# EAFDSS - Electronic Fiscal Signature Devices Library
#          Ειδική Ασφαλής Φορολογική Διάταξη Σήμανσης (ΕΑΦΔΣΣ)
#
# Copyright (C) 2008 Hasiotis Nikos
#
# ID: $Id$

package EAFDSS::Micrelec;

use 5.006001;
use strict;
use warnings;
use Switch;
use Data::Dumper;

use base qw ( EAFDSS::Base );

sub PROTO_DetailSign {
	my($self) = shift @_;
	my($fh)   = shift @_;

	my($reply, $totalSigns, $dailySigns, $date, $time, $sign) = $self->GetSign($fh);

	if ($reply == 0) {
		return ($reply, sprintf("%s %04d %08d %s%s %s", $sign, $dailySigns, $totalSigns, $self->date6ToHost($date), substr($time, 0, 4), $self->{SN}));
	} else {
		return (-1);
	}
}

sub PROTO_GetSign {
	my($self) = shift @_;
	my($fh)   = shift @_;

	my($chunk, %reply);
	$self->debug(  "[EAFDSS::Micrelec]::[Sign]");
	do {
		%reply = $self->SendRequest(0x21, 0x00, "{/0");
		if ($reply{DATA} =~ /^0E/) {
			sleep 1;
		}
	} until ($reply{DATA} !~ /^0E/);

	if ( %reply && ($reply{OPCODE} == 0x22) ) {
		while (read($fh, $chunk, 400)) {
			my(%reply) = $self->SendRequest(0x21, 0x00, "@/$chunk");
		}
		%reply = $self->SendRequest(0x21, 0x00, "}");
	}

	if (%reply) { 
		my($replyCode, $status1, $status2, $totalSigns, $dailySigns, $date, $time, $sign, $sn, $nextZ) = split(/\//, $reply{DATA});
		return ($replyCode, $totalSigns, $dailySigns, $date, $time, $nextZ, $sign);
	} else {
		return (-1);
	}
}

sub PROTO_SetHeader {
	my($self)    = shift @_;
	my($headers) = shift @_;

	$self->debug(  "[EAFDSS::Micrelec]::[SetHeader]");
	my(%reply) = $self->SendRequest(0x21, 0x00, "H/$headers");

	if (%reply) {
		my($replyCode, $status1, $status2) = split(/\//, $reply{DATA});
		return (hex($replyCode));
	} else {
		return (-1);
	}
}

sub PROTO_GetStatus {
	my($self) = shift @_;

	$self->debug("Get Status");
	my(%reply) = $self->SendRequest(0x21, 0x00, "?");

	if (%reply) {
		my($replyCode, $status1, $status2) = split(/\//, $reply{DATA});
		return (hex($replyCode), hex($status1), hex($status2));
	} else {
		return ($self->error());
	}
}

sub PROTO_GetHeader {
	my($self) = shift @_;

	$self->debug(  "[EAFDSS::Micrelec]::[GetHeader]");
	my(%reply) = $self->SendRequest(0x21, 0x00, "h");
	if (%reply) {
		my($replyCode, $status1, $status2, @header) = split(/\//, $reply{DATA});
		my($i);
		for ($i=0; $i < 12; $i+=2) {
			$header[$i+1] =~ s/\s*$//;
		}

		return (hex($replyCode), @header);
	} else {
		return (-1);
	}
}

sub PROTO_ReadTime {
	my($self) = shift @_;

	$self->debug(  "[EAFDSS::Micrelec]::[ReadTime]");
	my(%reply) = $self->SendRequest(0x21, 0x00, "t");

	if (%reply) {
		my($replyCode, $status1, $status2, $date, $time) = split(/\//, $reply{DATA});
		my($day) = substr($date, 0, 2);
		my($month) = substr($date, 2, 2);
		my($year) = substr($date, 4, 2);
		my($hour) = substr($time, 0, 2);
		my($min) = substr($time, 2, 2);
		my($sec) = substr($time, 4, 2);
		return (hex($replyCode), sprintf("%s/%s/%s %s:%s:%s", $day, $month, $year, $hour, $min, $sec ));
	} else {
		return (-1);
	}
}

sub PROTO_ReadDeviceID {
	my($self) = shift @_;

	$self->debug(  "[EAFDSS::Micrelec]::[ReadDeviceID]");
	my(%reply) = $self->SendRequest(0x21, 0x00, "a");

	if (%reply) {
		my($replyCode, $status1, $status2, $deviceId) = split(/\//, $reply{DATA});
		return (hex($replyCode), $deviceId);
	} else {
		return (-1);
	}
}

sub PROTO_VersionInfo {
	my($self) = shift @_;

	$self->debug(  "[EAFDSS::Micrelec]::[VersionInfo]");
	my(%reply) = $self->SendRequest(0x21, 0x00, "v");

	if (%reply) {
		my($replyCode, $status1, $status2, $vendor, $model, $version) = split(/\//, $reply{DATA});
		return (hex($replyCode), sprintf("%s %s version %s", $vendor, $model, $version));
	} else {
		return (-1);
	}
}

sub PROTO_DisplayMessage {
	my($self) = shift @_;
	my($msg)  = shift @_;

	$self->debug(  "[EAFDSS::Micrelec]::[VersionInfo]");
	my(%reply) = $self->SendRequest(0x21, 0x00, "7/1/$msg");

	if (%reply) {
		my($replyCode, $status1, $status2) = split(/\//, $reply{DATA});
		return (hex($replyCode));
	} else {
		return (-1);
	}
}

sub PROTO_ReadSignEntry {
	my($self)  = shift @_;
	my($index) = shift @_;

	$self->debug(  "[EAFDSS::Micrelec]::[VersionInfo]");
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
	my(%reply, $replyCode, $status1, $status2, $totalSigns, $dailySigns, $date, $time, $z, $sn, $closure);

	$self->debug(  "[EAFDSS::Micrelec]::[ReadClosure]");
	do {
		%reply = $self->SendRequest(0x21, 0x00, "R/$index");
		if (%reply) {
			($replyCode, $status1, $status2, $totalSigns, $dailySigns, $date, $time, $z, $sn, $closure) = split(/\//, $reply{DATA});
		} else {
			return (-1);
		}
		if ($replyCode =~ /^0E$/) {
			sleep 1;
		}
	} until ($replyCode !~ /^0E$/);

	return (hex($replyCode), $status1, $status2, $totalSigns, $dailySigns, $date, $time, $z, $sn, $closure);
}

sub PROTO_ReadSummary {
	my($self)  = shift @_;
	my(%reply, $replyCode, $status1, $status2, $lastZ, $total, $daily, $signBlock, $remainDaily);

	$self->debug(  "[EAFDSS::Micrelec]::[ReadSummary]");
	do {
		my(%reply) = $self->SendRequest(0x21, 0x00, "Z");
		if (%reply) {
			($replyCode, $status1, $status2, $lastZ, $total, $daily, $signBlock, $remainDaily) = split(/\//, $reply{DATA});
		} else {
			return (-1);
		}
		if ($replyCode =~ /^0E$/) {
			sleep 1;
		}
	} until ($replyCode !~ /^0E$/);

	return (hex($replyCode), $status1, $status2, $lastZ, $total, $daily, $signBlock, $remainDaily);
}

sub PROTO_IssueReport {
	my($self)  = shift @_;
	my(%reply, $replyCode, $status1, $status2);

	$self->debug(  "[EAFDSS::Micrelec]::[VersionInfo]");
	%reply = $self->SendRequest(0x21, 0x00, "x/2/0");

	if (%reply) {
		my($replyCode, $status1, $status2) = split(/\//, $reply{DATA});
		return (hex($replyCode));
	} else {
		return (-1);
	}
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
