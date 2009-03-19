# EAFDSS - Electronic Fiscal Signature Devices Library
#          Ειδική Ασφαλής Φορολογική Διάταξη Σήμανσης (ΕΑΦΔΣΣ)
#
# Copyright (C) 2008 Hasiotis Nikos
#
# ID: $Id$

package EAFDSS::SDSP;

use 5.006001;
use strict;
use warnings;
use POSIX;

use Carp;
use Class::Base;
use Device::SerialPort;
use Data::Dumper;

use base qw (EAFDSS::Micrelec );

our($VERSION) = '0.20';

my($control) = {
		'ACK' => chr(0x06),
		'NAK' => chr(0x15),
		'STX' => chr(0x02),
		'ETX' => chr(0x03),
		'CAN' => chr(0x18),
		'ENQ' => chr(0x05)
	};

sub init {
	my($class)  = shift @_;
	my($config) = @_;
	my($self)   = $class->SUPER::init(@_);

	$self->debug("Initializing");

	if (! exists $config->{PARAMS}) {
		return $self->error("No parameters have been given!");
	} else {
		$self->{SERIAL} = $config->{PARAMS};
		$self->{BAUD}   = 115200;
	}

	$self->debug("  Serial Device Initialization [%s]", $self->{SERIAL});
	$self->{_SERIAL} = Device::SerialPort->new($self->{SERIAL});
	if (! defined $self->{_SERIAL}) {
		return undef;
	}

	$self->{_SERIAL}->baudrate($self->{BAUD});
	$self->{_SERIAL}->parity("none");
	$self->{_SERIAL}->databits(8);
	$self->{_SERIAL}->stopbits(1); 

	my($reply, $deviceID) = $self->PROTO_ReadDeviceID();
	if ( ($reply == 0) && ($deviceID ne $self->{SN}) ) {
		return $self->error("Serial Number not matching");
	}

	return $self;
}

sub SendRequest {
	my($self)   = shift @_;
	my($opcode) = shift @_;
	my($opdata) = shift @_;
	my($data)   = shift @_;

	my(%reply) = ();

	my($try, $state);
	$self->{_SERIAL}->read_const_time(3000);
	$self->{_SERIAL}->read_char_time(0);
	$state = "ENQ";
	for ($try = 1; $try <= 3; $try++) {
		my($count_out);
		$self->debug("    Sending ENQ [try %d]", $try);
		$count_out = $self->{_SERIAL}->write($control->{'CAN'});
		$count_out = $self->{_SERIAL}->write($control->{'CAN'});
		$count_out = $self->{_SERIAL}->write($control->{'CAN'});
		$count_out = $self->{_SERIAL}->write($control->{'ENQ'});
		$self->{_SERIAL}->write_drain();
		if ($count_out) {
			my($count_in, $ack) = $self->{_SERIAL}->read(1);
			if ($count_in && ($ack eq $control->{'ACK'} ) ) {
				$self->debug("      Got ACK to ENQ");
				$state = "PACKET";
				last;
			}
		}
	}
	if ($state ne "PACKET") {
		$reply{DATA}   = "02/0/";
		return %reply;
	}

	my($packet) = sprintf("%s%s/%02d%s", $control->{'STX'}, $data, $self->_checksum($data . "/"), $control->{'ETX'}); 
	my($ppacket) = sprintf("%s.../%02d", substr($data, 0, 10), $self->_checksum($data . "/")); 
	$self->debug("    Build packet for data[%s]", $ppacket);
	for ($try = 1; $try <= 3; $try++) {
		my($count_out);
		$self->debug("    Sending PACKET [try %d]", $try);
		$count_out = $self->{_SERIAL}->write($packet);
		$self->{_SERIAL}->write_drain();
		if ($count_out == length($packet) ) {
			my($count_in, $ack) = $self->{_SERIAL}->read(1);
			if ($count_in && ($ack eq $control->{'ACK'} ) ) {
				$self->debug("      Got ACK to PACKET send");
				$state = "REPLY";
				last;
			}
			if ($count_in && ($ack eq $control->{'NAK'} ) ) {
				$reply{OPCODE} = 0x13;
				$self->debug("      Got NAK to PACKET send");
			}
		}
	}
	if ($state ne "REPLY") {
		$reply{DATA}   = "02/0/";
		return %reply;
	}

	my($full_reply, $reply, $checksum);
	for ($try = 1; $try <= 3; $try++) {
		$full_reply = "";
		$self->debug("    Receiving REPLY [try %d]", $try);
		my($count_in, $ack) = $self->{_SERIAL}->read(1);
		if ($count_in && ($ack eq $control->{'STX'}) ) {
			my($count_in, $c);
			do {
				($count_in, $c) = $self->{_SERIAL}->read(1);
				if ($count_in && ($c ne $control->{'ETX'} ) ) {
					$full_reply .= $c;
				}
			} until ($c eq $control->{'ETX'});
			$full_reply =~ /(.*)\/(\d\d)$/;
			($reply, $checksum) =  ($1, $2);
			if ( $checksum == $self->_checksum($reply . "/")) {
				$self->debug("      Got Reply [%s]", $reply);
				$self->{_SERIAL}->write($control->{'ACK'});
				$state = "DONE";
				last;
			} else {
				$self->{_SERIAL}->write($control->{'NAK'});
				$self->debug("      Discarding because of bad checksum");
			}
		}
	}
	if ($state ne "DONE") {
		$reply{DATA}   = "02/0/";
		return %reply;
	}

	$reply{DATA}   = $reply;	
	return %reply;
}

sub _checksum {
	my($self) = shift @_;
	my($data) = shift @_; 

	$data = $data;
	my($i, $checksum) = (0, 0);
	for ($i=0; $i < length($data); $i++) {
		if (ord substr($data, $i, 1) != 10) {
			$checksum += ord substr($data, $i, 1);
		}
		$checksum = $checksum % 256;
		#printf("[%s %3d :: %4d :: %3d]\n",  substr($data, $i, 1), ord substr($data, $i, 1), $checksum, $checksum % 100);
	}

	return $checksum % 100;
}

# Preloaded methods go here.

1;
__END__

=head1 NAME

EAFDSS::SDSP - EAFDSS Driver for Micrelec SDSP Devices


=head1 DESCRIPTION

Read EAFDSS on how to use the module.

=head1 VERSION

This is version 0.20.

=head1 AUTHOR

Hasiotis Nikos, E<lt>hasiotis@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Hasiotis Nikos

This library is free software; you can redistribute it and/or modify
it under the terms of the LGPL or the same terms as Perl itself,
either Perl version 5.8.8 or, at your option, any later version of
Perl 5 you may have available.

=cut
