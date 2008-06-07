# EAFDSS - Electronic Fiscal Signature Devices Library
#          Ειδική Ασφαλής Φορολογική Διάταξη Σήμανσης (ΕΑΦΔΣΣ)
#
# Copyright (C) 2008 Hasiotis Nikos
#
# ID: $Id$


package EAFDSS::SDNP;

use 5.006001;
use strict;
use warnings;
use Socket;
use Time::HiRes qw ( setitimer ITIMER_REAL time );
use IO::Socket::INET;
use base qw(EAFDSS::Micrelec);
use Data::Dumper;
use Carp;

our @ISA = qw(EAFDSS::Micrelec);
our $VERSION = '0.10';

sub new {
	my($class) = shift @_;
	my($self) = $class->SUPER::new(@_);

	$self->_Debug($self->{LEVEL}{INFO}, "[EAFDSS::SDNP]::[new]");

	$self->_Debug($self->{LEVEL}{INFO}, "    Socket Initialization to IP [%s]", $self->{IP});
	$self->{_SOCKET} = new IO::Socket::INET->new(PeerPort=>24222, Proto=>'udp', PeerAddr=> $self->{IP});

	$self->_Debug($self->{LEVEL}{INFO}, "    Setting synced to FALSE");
	$self->{_SYNCED} = 0;

	$self->_Debug($self->{LEVEL}{INFO}, "    Setting timers");
	$self->{_TSYNC} = 0;
	$self->{_T0}    = 0;
	$self->{_T1}    = 0;

	$self->_Debug($self->{LEVEL}{INFO}, "    Setting frame counter to 1");
	$self->{_FSN}    = 1;

	return $self;
}

sub _initVars {
	my($self)  = shift @_;

	$self->SUPER::_initVars(@_);

	my(%params);
	while ( @_ ) {
		my($key) = uc(shift @_);
		$params{$key} = shift @_;
	}

	if (! exists $params{IP}) {
		$self->_Debug($self->{LEVEL}{ERROR}, "    You need to provide the IP of the device!");
	} else {
		$self->{IP} = $params{IP};
	}
}

sub Status {
	my($self)  = shift @_;

	$self->_Debug($self->{LEVEL}{INFO}, "[EAFDSS::SDNP]::[Status]");
	my(%reply) = $self->SendRequest(0x21, 0x00, "v");

	return $reply{DATA};
}

sub sdnpQuery {
}

sub sdnpSync {
	my($self)  = shift @_;

	# Set connection state to UNSYNCHRONIZED;
	$self->{_SYNC} = 0;
	
	# For at least 6 times do:
	my($try);
	local $SIG{ALRM} = sub { $self->{_T0} -= 0.100; $self->{_T1} -= -.100};
	setitimer(ITIMER_REAL, 0.100, 0.100);
	for ($try = 1; $try < 6; $try++) {
		$self->_Debug($self->{LEVEL}{INFO}, "    Send Sync Request try #%d", $try);

		# Set timer T0 to 500 milliseconds;
		$self->{_T0} = 1;
		
		# Select a random initial FSN (IFSN); 
		$self->{_FSN} = int(rand(32768) + 1);

		# Send SYNC(IFSN) frame to connection IP address;
		my($msg) = $self->sdnpPacket(0x11, 0x00);
		$self->sdnpPrintFrame("      ----> [%s]", $msg);
		$self->{_SOCKET}->send($msg);

		# Do until T0 expires:
		while ($self->{_T0} > 0) {
			my(%reply)  = ();
			my($frame)  = undef;

			$self->{_SOCKET}->recv($frame, 512);
			if ($frame) {
				%reply = $self->analyzeFrame($frame);
				$self->sdnpPrintFrame("      <---- [%s]", $frame);
				$reply{'HOST'} = $self->{_SOCKET}->peerhost();
			} else {
				$reply{HOST} = -1;
			}

			# If a valid frame received then:
			if ($self->sdnpFrameCheck(\%reply)) {
				# If frame type is ACK
				if ($reply{OPCODE} == 0x12) {
					# If ACK(FSN) = IFSN then:
					if ($self->{_FSN} == $reply{SN}) {
						# Set connection NextFSN = IFSN + 1;
						$self->{_FSN}++;

						# Set connection state to SYNCHRONIZED;
						$self->{_SYNC} = 1;

						# Set connection SYNC timer to 4 seconds;
						$self->{_TSYNC} = 1;

						# Return sync success;
						$self->{_T0} = 0;
						setitimer(ITIMER_REAL, 0, 0);
						return 1;
					} 
				} else {
					$self->_Debug($self->{LEVEL}{INFO}, "   SYNC NOT ACKed!");
				}
			}
		}
	}

	$self->{_TIMER} = 0;
	setitimer(ITIMER_REAL, 0, 0);

	return 0;
}

sub SendRequest {
	my($self)   = shift @_;
	my($opcode) = shift @_;
	my($opdata) = shift @_;
	my($data)   = shift @_;

	my(%reply) = ();

	# For at least 6 times do:
	my($try);
	local $SIG{ALRM} = sub { $self->{_T0} -= 0.100; $self->{_T1} -= -.100};
	setitimer(ITIMER_REAL, 0.100, 0.100);
	for ($try = 1; $try < 6; $try++) {
		my(%reply)  = ();
		$self->_Debug($self->{LEVEL}{INFO}, "    Send Request try #%d", $try);
		SYNC:
		# If state is UNSYNCHRONIZED or connection SYNC timer expired then:
		if (1) {
			if ( $self->sdnpSync() == 0) {
				$self->_Debug($self->{LEVEL}{INFO}, "        Sync Failed");
				setitimer(ITIMER_REAL, 0, 0);
				return %reply;
			}
		}

		SEND:
		# Send REQUEST(Connection's NextFSN) using 'RequestDataPacket';
		my($msg) = $self->sdnpPacket($opcode, $opdata, $data);
		$self->sdnpPrintFrame("      ----> [%s]", $msg);
		$self->{_SOCKET}->send($msg);

		# Set T0 timer to 800 milliseconds;
		$self->{_T0} = 1;
		
		# Do until T0 expires:
		while ($self->{_T0} > 0) {
			my($frame)  = undef;

			$self->{_SOCKET}->recv($frame, 512);
			if ($frame) {
				%reply = $self->analyzeFrame($frame);
				$self->sdnpPrintFrame("      <---- [%s]", $frame);
				$reply{'HOST'} = $self->{_SOCKET}->peerhost();
			} else {
				$reply{HOST} = -1;
			}

			# If a valid SDNP frame received then do
			if ($self->sdnpFrameCheck(\%reply)) {
				# If received frame's FSN <> Request frame's FSN
				if ($self->{_FSN} != $reply{SN}) {
					$self->_Debug($self->{LEVEL}{INFO}, "        Bad FSN, Discarding");
					next;
				} else {
					# Test received frame's opcode;
					# Case RST:
					if ($reply{OPCODE} == 0x10) {
						# Set connection's state to UNSYNCHRONIZED;
						$self->{_SYNC} = 0;
						goto SYNC;
					}
					# Case NAK:
					if ($reply{OPCODE} == 0x13) {
						goto SEND;
					}
					# Case REPLY:
					if ($reply{OPCODE} == 0x22) {
						# If received frame's data packet does not validate okay then:
						my($i, $checksum) = (0, 0xAA55);
						for ($i=0; $i < length($reply{DATA}); $i++) {
							$checksum += ord substr($reply{DATA}, $i, 1);
						}
						$self->_Debug($self->{LEVEL}{DEBUG}, "        Checking Data checksum [%04X]", $checksum);
						if ($checksum != $reply{CHECKSUM}) {
							# Create and send NAK frame with FSN set to received FSN;
							my($msg) = $self->sdnpPacket(0x13, 0x00);
							$self->sdnpPrintFrame("      ----> [%s]", $msg);
							$self->{_SOCKET}->send($msg);
							next;
						} else {
							# Renew connection's SYNC timer;
							$self->{_TSYNC} = 1;

							# Advance connection's NextFSN by one;
							$self->{_FSN}++;

							# Return request transmittion success;
							setitimer(ITIMER_REAL, 0, 0);
							return %reply;
						}
					}
					$self->_Debug($self->{LEVEL}{INFO}, "        Bad Frame, Discarding");
					next;
				}
			} else {
				$self->_Debug($self->{LEVEL}{INFO}, "        Bad Frame, Discarding");
			}
		}
	}

	# Return request transmittion failure;
	setitimer(ITIMER_REAL, 0, 0);
	return %reply;
}

sub sdnpFrameCheck {
	my($self)   = shift @_;
	my($frame)  = shift @_;

	$self->_Debug($self->{LEVEL}{DEBUG}, "    Checking Frame");

	# Check sender ip
	my($ip) = inet_ntoa(inet_aton($self->{IP})); 
	#my($ip) = inet_ntoa(inet_aton("gattaca")); 
	$self->_Debug($self->{LEVEL}{DEBUG}, "        Comparing [%s][%s]", $frame->{HOST}, $ip);
	if ($frame->{HOST} ne $ip) {
		return 0;
	}

	# Check if size of UDP frame < size of SDNP header then: 
	$self->_Debug($self->{LEVEL}{DEBUG}, "        Checking frame size [%d]", length($frame->{RAW}));
	if (length($frame->{RAW}) < 12) {
		return 0;
	}

	# Check if size of UDP frame > 512 then:
	if (length($frame) > 512) {
		return 0;
	}

	# Check if SDNP header checksum does not validate okay then:
	my($i, $checksum) = (0, 0xAA55);
	for ($i=0; $i < 10 ; $i++) {
		$checksum += ord substr($frame->{RAW}, $i, 1);
	}
	$self->_Debug($self->{LEVEL}{DEBUG}, "        Checking frame header checksum [%04X]", $checksum);
	if ($checksum != $frame->{HEADER_CHECKSUM}) {
		return 0;
	}

	# Check if UDP frame size <> SDNP header data length +  SDNP header size then:
	$self->_Debug($self->{LEVEL}{DEBUG}, "        Checking UDP frame size [%d]", length($frame->{RAW}));
	if (length($frame->{RAW}) != 12 + $frame->{LENGTH}) {
		return 0;
	}

	# Check if frame id in SDNP header <> SDNP device protocol id then:
	$self->_Debug($self->{LEVEL}{DEBUG}, "        Checking frame id [%04X]", $frame->{ID});
	if ($frame->{ID} != 0x7A2D) {
		return 0;
	}

	# Return success;
	return 1;
}

sub sdnpPacket {
	my($self)   = shift @_;

	my($i);

	my($frame_id) = 0xE18F;
	my($frame_sn) = $self->{_FSN};
	my($opcode)   = shift @_;
	my($opdata)   = shift @_; 
	my($data)     = shift @_; 
	my($length)   = 0x0000;
	my($checksum) = 0xAA55;
	my($header)   = 0xAA55;

	if ($data) {
		$length = length($data); 
		for ($i=0; $i < length($data); $i++) {
			$checksum += ord substr($data, $i, 1);
		}
	} else {
		$data = "";
	}

	my($retValue) = pack("SSCCSS", $frame_id, $frame_sn, $opcode, $opdata, $length, $checksum);
	for ($i=0; $i < length($retValue); $i++) {
		$header += ord substr($retValue, $i, 1);
	}

	return pack("SSCCSSS", $frame_id, $frame_sn, $opcode, $opdata, $length, $checksum, $header) . $data;
}

sub sdnpPrintFrame {
	my($self)   = shift @_;
	my($format) = shift @_;
	my($msg)    = shift @_;

	my($i, $tmpString);
	for ($i=0; $i < 11; $i++) {
		$tmpString .= sprintf("%02X::", ord substr($msg, $i, 1));
	}
	$tmpString .= sprintf("%02X", ord substr($msg, length($msg) - 1, 1));
	$self->_Debug($self->{LEVEL}{INFO}, $format, $tmpString);

	my(%frame) = $self->analyzeFrame($msg);
	$self->_Debug($self->{LEVEL}{DEBUG}, "\t    ID..................[%04X]", $frame{ID});
	$self->_Debug($self->{LEVEL}{DEBUG}, "\t    SN..................[%04X]", $frame{SN});
	$self->_Debug($self->{LEVEL}{DEBUG}, "\t    OPCODE..............[  %02X]", $frame{OPCODE});
	$self->_Debug($self->{LEVEL}{DEBUG}, "\t    OPDATA..............[  %02X]", $frame{OPDATA});
	$self->_Debug($self->{LEVEL}{DEBUG}, "\t    LENGTH..............[%04X]", $frame{LENGTH});
	$self->_Debug($self->{LEVEL}{DEBUG}, "\t    CHECKSUM............[%04X]", $frame{CHECKSUM});
	$self->_Debug($self->{LEVEL}{DEBUG}, "\t    HEADER_CHECKSUM.....[%04X]", $frame{HEADER_CHECKSUM});
	$self->_Debug($self->{LEVEL}{DEBUG}, "\t    DATA................[%s]", $frame{DATA});

	return; 
}

sub analyzeFrame {
	my($self) = shift @_;
	my($msg)  = shift @_;

	my(%retValue) = ();

	$retValue{RAW} = $msg;
	$retValue{ID} = unpack("S", substr($msg,  0, 2));
	$retValue{SN} = unpack("S", substr($msg,  2, 2));
	$retValue{OPCODE} = unpack("C", substr($msg,  4, 1)); 
	$retValue{OPDATA} = unpack("C", substr($msg,  5, 1));
	$retValue{LENGTH} = unpack("S", substr($msg,  6, 2));
	$retValue{CHECKSUM} = unpack("S", substr($msg,  8, 2));
	$retValue{HEADER_CHECKSUM} = unpack("S", substr($msg,  10, 2));
	$retValue{DATA} = substr($msg, 12);

	return %retValue; 
}

# Preloaded methods go here.

1;
__END__

=head1 NAME

EAFDSS::SDNP - Micrelec Network Electronic Fiscal Signature Devices Library

=head1 SYNOPSIS

  use EAFDSS::SDNP; 

  my($FD) = new EAFDSS::SDNP(
		DIR   => "/tmp/SIGNS",
		SN    => "AAA0000001",
		IP    => "192.168.100.101",
	);
  print $FD->Sign("invoice.txt");

=head1 DESCRIPTION

First you initialize your Device Object and then you simply invoke the "Sign" method.
More  to come soon.

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
