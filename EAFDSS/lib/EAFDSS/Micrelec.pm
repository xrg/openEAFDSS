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
use base qw(EAFDSS::Base);
use Data::Dumper;
use Carp;

our @ISA = qw(EAFDSS::Base);
our $VERSION = '0.10';

sub new {
	my($class) = shift @_;
	my($self)  = $class->SUPER::new(@_);

	$self->_Debug($self->{LEVEL}{DEBUG}, "[EAFDSS::Micrelec]::[new]");

	return $self;
}

sub GetFullSign {
	my($self) = shift @_;
	my($fh)   = shift @_;

	my($reply, $totalSigns, $dailySigns, $date, $time, $sign) = $self->GetSign($fh);

	if ($reply == 0) {
		return ($reply, sprintf("%s %04d %08d %s%s %s", $sign, $dailySigns, $totalSigns, $self->date6ToHost($date), substr($time, 0, 4), $self->{SN}));
	} else {
		return (-1);
	}
}

sub GetSign {
	my($self) = shift @_;
	my($fh)   = shift @_;

	my($chunk);
	$self->_Debug($self->{LEVEL}{DEBUG}, "[EAFDSS::Micrelec]::[Sign]");
	my(%reply) = $self->SendRequest(0x21, 0x00, "{/0");
	if ( %reply && ($reply{OPCODE} == 0x22) ) {
		while (read($fh, $chunk, 400)) {
			my(%reply) = $self->SendRequest(0x21, 0x00, "@/$chunk");
		}
		%reply = $self->SendRequest(0x21, 0x00, "}");
	}
	if (%reply) { 
		my($replyCode, $status1, $status2, $totalSigns, $dailySigns, $date, $time, $sign, $sn, $nextZ) = split(/\//, $reply{DATA});
		return ($replyCode, $totalSigns, $dailySigns, $date, $time, $sign);
	} else {
		return (-1);
	}
}

sub SetHeader {
	my($self)    = shift @_;
	my($headers) = shift @_;

	$self->_Debug($self->{LEVEL}{DEBUG}, "[EAFDSS::Micrelec]::[SetHeader]");
	my(%reply) = $self->SendRequest(0x21, 0x00, "H/$headers");

	if (%reply) {
		my($replyCode, $status1, $status2) = split(/\//, $reply{DATA});
		return (hex($replyCode));
	} else {
		return (-1);
	}
}

sub GetStatus {
	my($self) = shift @_;

	$self->_Debug($self->{LEVEL}{DEBUG}, "[EAFDSS::Micrelec]::[GetStatus]");
	my(%reply) = $self->SendRequest(0x21, 0x00, "?");

	if (%reply) {
		my($replyCode, $status1, $status2) = split(/\//, $reply{DATA});
		return (hex($replyCode), hex($status1), hex($status2));
	} else {
		return (-1);
	}
}

sub GetHeader {
	my($self) = shift @_;

	$self->_Debug($self->{LEVEL}{DEBUG}, "[EAFDSS::Micrelec]::[GetHeader]");
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

sub ReadTime {
	my($self) = shift @_;

	$self->_Debug($self->{LEVEL}{DEBUG}, "[EAFDSS::Micrelec]::[ReadTime]");
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

sub ReadDeviceID {
	my($self) = shift @_;

	$self->_Debug($self->{LEVEL}{DEBUG}, "[EAFDSS::Micrelec]::[ReadDeviceID]");
	my(%reply) = $self->SendRequest(0x21, 0x00, "a");

	if (%reply) {
		my($replyCode, $status1, $status2, $deviceId) = split(/\//, $reply{DATA});
		return (hex($replyCode), $deviceId);
	} else {
		return (-1);
	}
}

sub VersionInfo {
	my($self) = shift @_;

	$self->_Debug($self->{LEVEL}{DEBUG}, "[EAFDSS::Micrelec]::[VersionInfo]");
	my(%reply) = $self->SendRequest(0x21, 0x00, "v");

	if (%reply) {
		my($replyCode, $status1, $status2, $vendor, $model, $version) = split(/\//, $reply{DATA});
		return (hex($replyCode), sprintf("%s %s version %s", $vendor, $model, $version));
	} else {
		return (-1);
	}
}

sub DisplayMessage {
	my($self) = shift @_;
	my($msg)  = shift @_;

	$self->_Debug($self->{LEVEL}{DEBUG}, "[EAFDSS::Micrelec]::[VersionInfo]");
	my(%reply) = $self->SendRequest(0x21, 0x00, "7/1/$msg");

	if (%reply) {
		my($replyCode, $status1, $status2) = split(/\//, $reply{DATA});
		return (hex($replyCode));
	} else {
		return (-1);
	}
}

sub ReadSignEntry {
	my($self)  = shift @_;
	my($index) = shift @_;

	$self->_Debug($self->{LEVEL}{DEBUG}, "[EAFDSS::Micrelec]::[VersionInfo]");
	my(%reply) = $self->SendRequest(0x21, 0x00, "\$/$index");

	if (%reply) {
		my($replyCode, $status1, $status2, $sign) = split(/\//, $reply{DATA});
		return (hex($replyCode), $sign);
	} else {
		return (-1);
	}
}

sub ReadClosure {
	my($self)  = shift @_;
	my($index) = shift @_;

	$self->_Debug($self->{LEVEL}{DEBUG}, "[EAFDSS::Micrelec]::[VersionInfo]");
	my(%reply) = $self->SendRequest(0x21, 0x00, "R/$index");
	if (%reply) {
		my($replyCode, $status1, $status2, $total, $daily, $date, $time, $z) = split(/\//, $reply{DATA});
		return (hex($replyCode), $z);
	} else {
		return (-1);
	}
}

sub ReadSummary {
	my($self)  = shift @_;

	$self->_Debug($self->{LEVEL}{DEBUG}, "[EAFDSS::Micrelec]::[VersionInfo]");
	my(%reply) = $self->SendRequest(0x21, 0x00, "Z");

	return %reply; 
}

sub IssueReport {
	my($self)  = shift @_;

	$self->_Debug($self->{LEVEL}{DEBUG}, "[EAFDSS::Micrelec]::[VersionInfo]");
	my(%reply) = $self->SendRequest(0x21, 0x00, "x/2/0");

	if (%reply) {
		my($replyCode, $status1, $status2, $z) = split(/\//, $reply{DATA});
		return (hex($replyCode), $z);
	} else {
		return (-1);
	}
}

sub errMessage {
	my($self)    = shift @_;
	my($errCode) = shift @_;

	if ($errCode == -1) {
		return("Device not accessible", "Check the network");
	} elsif ($errCode == 0x00) {
		return("No errors - success", "None");
	} elsif ($errCode == 0x01) {
		return("Wrong number of fields", "Check the command's field count");
	} elsif ($errCode == 0x02) {
		return("Field too long", "A field is long: check it & retry");
	} elsif ($errCode == 0x03) {
		return("Field too small", "A field is small: check it & retry");
	} elsif ($errCode == 0x04) {
		return("Field fixed size mismatch", "A field size is wrong: check it & retry");
	} elsif ($errCode == 0x05) {
		return("Field range or type check failed", "Check ranges or types in command");
	} elsif ($errCode == 0x06) {
		return("Bad request code", "Correct the request code (unknown)");
	} elsif ($errCode == 0x09) {
		return("Printing type bad", "Correct the specified printing style");
	} elsif ($errCode == 0x0A) {
		return("Cannot execute with day open", "Issue a Z report to close the day");
	} elsif ($errCode == 0x0B) {
		return("RTC programming requires jumper", "Short the 'clock' jumper and retry");
	} elsif ($errCode == 0x0C) {
		return("RTC date or time invalid", "Check the date/time range. Also check if date is prior to a date of a fiscal record");
	} elsif ($errCode == 0x0D) {
		return("No records in fiscal period", "No suggested action; the operation cannot be executed in the specified period");
	} elsif ($errCode == 0x0E) {
		return("Device is busy in another task", "Wait for the device to get ready");
	} elsif ($errCode == 0x0F) {
		return("No more header records allowed", "No suggested action; the header programming cannot be executed because the fiscal memory cannot hold more records");
	} elsif ($errCode == 0x10) {
		return("Cannot execute with block open", "The specified command requires no open signature block for proceeding. Closethe block and retry");
	} elsif ($errCode == 0x11) {
		return("Block not open", "The specified command requires a signature block to be open to execute. Open a block and retry");
	} elsif ($errCode == 0x12) {
		return("Bad data stream", "Means that the passed data to be signed are of incorrect format. The expected format is in HEX (hexadecimal) pairs, so expected field must have an even size and its contents must be in range '0'-'9' or 'A'-'F' inclusive");
	} elsif ($errCode == 0x13) {
		return("Bad signature field", "Means that the passed signature is of incorrect format. The expected format is of 40 characters formatted as 20 HEX (hexadecimal) pairs");
	} elsif ($errCode == 0x14) {
		return("Z closure time limit", "Means that 24 hours passed from the last Z closure. Issue a Z and retry");
	} elsif ($errCode == 0x15) {
		return("Z closure not found", "The specified Z closure number does not exist. Pass an existing Z number");
	} elsif ($errCode == 0x16) {
		return("Z closure record bad", "The requested Z record is unreadable (damaged). Device requires service");
	} elsif ($errCode == 0x17) {
		return("User browsing in progress", "The user is accessing the device by manual operation. The protocol usage is suspended until the user terminates the keyboard browsing. Just wait or inform application user");
	} elsif ($errCode == 0x18) {
		return("Signature daily limit reached", "The max number of signatures in a day have been issued. A Z closure is needed to free the daily storage memory");
	} elsif ($errCode == 0x19) {
		return("Printer paper end detected", "Replace the paper roll and retry");
	} elsif ($errCode == 0x1A) {
		return("Printer is offline", "Printer disconnection. Service required");
	} elsif ($errCode == 0x1B) {
		return("Fiscal unit is offline", " Fiscal disconnection. Service required");
	} elsif ($errCode == 0x1C) {
		return("Fatal hardware error", "Mostly fiscal errors. Service required");
	} elsif ($errCode == 0x1D) {
		return("Fiscal unit is full", "Need fiscal replacement. Service");
	} elsif ($errCode == 0x1E) {
		return("No data passed for signature", "Need to pass some data to close block");
	} elsif ($errCode == 0x1F) {
		return("Signature does not exist", "Correct requested signature number");
	} elsif ($errCode == 0x20) {
		return("Battery fault detected", "If problem persists, service required");
	} elsif ($errCode == 0x21) {
		return("Recovery in progress", "This command is not allowed when a recovery has started. Finish the recovery procedure and retry");
	} elsif ($errCode == 0x22) {
		return("Recovery only after CMOS reset", "Attempted to initiate a recovery procedure without a previous CMOS reset. The recovery is not needed");
	} elsif ($errCode == 0x23) {
		return("Real-Time Clock needs programming", "This means that the RTC has invalid data and needs to be reprogrammed. As a consequence, service is needed");
	} elsif ($errCode == 0x24) {
		return("Z closure date warning", "This is an error returned by a closure request, when the RTC's date has a value at least 48 hours later than the last closure time stamp (see XZreport)");
	} elsif ($errCode == 0x25) {
		return("Bad character in stream", "This error is returned when a stream sent contains one or more invalid characters. A table of allowed binary values is defined in 'table 2'. This error means that device has rejected the specified frame. A filtering of data sent to the device *must* be performed by host");
	} else {
		return(undef, undef);
	}
}

sub devStatus {
	my($self)   = shift @_;
	my($status) = sprintf("%08b", shift);
	my(@status) = split(//, $status);

	my($busy, $fatal, $paper, $cmos, $printer, $user, $fiscal, $battery) = 
		($status[7],$status[6],$status[5],$status[4],$status[3],$status[2],$status[1],$status[0]);

	return ($busy, $fatal, $paper, $cmos, $printer, $user, $fiscal, $battery);
}

sub appStatus {
	my($self)   = shift @_;

	my($status) = sprintf("%08b", shift);
	my(@status) = split(//, $status);

	my($day, $signature, $recovery, $fiscalWarn, $dailyFull, $fiscalFull) =
		($status[6],$status[5],$status[4],$status[2],$status[1],$status[0]);

	return ($day, $signature, $recovery, $fiscalWarn, $dailyFull, $fiscalFull);
}

sub date6ToHost {
	my($self) = shift @_;
	my($var) = shift @_;

	$var =~ s/(\d\d)(\d\d)(\d\d)/$3$2$1/;

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
