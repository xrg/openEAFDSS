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

sub GetSign {
	my($self) = shift @_;
	my($fh)   = shift @_;

	my($chunk);
	$self->_Debug($self->{LEVEL}{DEBUG}, "[EAFDSS::Micrelec]::[Sign]");
	my(%reply) = $self->SendRequest(0x21, 0x00, "{/0");
	if ($reply{OPCODE} == 0x22) {
		while (read($fh, $chunk, 400)) {
			my(%reply) = $self->SendRequest(0x21, 0x00, "@/$chunk");
		}
	}
	%reply = $self->SendRequest(0x21, 0x00, "}");
	my($replyCode, $status1, $status2, $totalSigns, $dailySigns, $date, $time, $sign, $sn, $nextZ) = split(/\//, $reply{DATA});

	return ( $totalSigns, $dailySigns, $date, $time, $sign);
}

sub SetHeader {
	my($self)    = shift @_;
	my($headers) = shift @_;

	$self->_Debug($self->{LEVEL}{DEBUG}, "[EAFDSS::Micrelec]::[SetHeader]");
	my(%reply) = $self->SendRequest(0x21, 0x00, "H/$headers");

	return %reply; 
}

sub GetStatus {
	my($self) = shift @_;

	$self->_Debug($self->{LEVEL}{DEBUG}, "[EAFDSS::Micrelec]::[GetStatus]");
	my(%reply) = $self->SendRequest(0x21, 0x00, "?");

	return %reply; 
}

sub GetHeader {
	my($self) = shift @_;

	$self->_Debug($self->{LEVEL}{DEBUG}, "[EAFDSS::Micrelec]::[GetHeader]");
	my(%reply) = $self->SendRequest(0x21, 0x00, "h");

	return %reply; 
}

sub ReadTime {
	my($self) = shift @_;

	$self->_Debug($self->{LEVEL}{DEBUG}, "[EAFDSS::Micrelec]::[ReadTime]");
	my(%reply) = $self->SendRequest(0x21, 0x00, "t");

	return %reply; 
}

sub ReadDeviceID {
	my($self) = shift @_;

	$self->_Debug($self->{LEVEL}{DEBUG}, "[EAFDSS::Micrelec]::[ReadDeviceID]");
	my(%reply) = $self->SendRequest(0x21, 0x00, "a");

	return %reply; 
}

sub VersionInfo {
	my($self) = shift @_;

	$self->_Debug($self->{LEVEL}{DEBUG}, "[EAFDSS::Micrelec]::[VersionInfo]");
	my(%reply) = $self->SendRequest(0x21, 0x00, "v");

	return %reply; 
}

sub DisplayMessage {
	my($self) = shift @_;
	my($msg)  = shift @_;

	$self->_Debug($self->{LEVEL}{DEBUG}, "[EAFDSS::Micrelec]::[VersionInfo]");
	my(%reply) = $self->SendRequest(0x21, 0x00, "7/1/$msg/");

	return %reply; 
}

sub BeginBlock {

}

sub SignBlock {

}

sub EndBlock {

}

sub CancelBlock {

}

sub ReadSignEntry {

}

sub ReadClosure {

}

sub ReadSummary {

}

sub IssueReport {

}

sub FiscalRepByZ {

}

sub FiscalRepByDate {

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
