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

	$self->_Debug($self->{LEVEL}{DEBUG}, "[EAFDSS::Base]::[Sign]");
	if (-e $fname) {
		$self->_Debug($self->{LEVEL}{DEBUG}, "  Signing file [%s]", $fname);
		open(FH, $fname);
		return $self->GetSign(*FH);
	} else {
		$self->_Debug($self->{LEVEL}{DEBUG}, "  No such file [%s]", $fname);
		return -1;
	}

	# Create A, B, C Files
}

sub FullSign {
	my($self)  = shift @_;
	my($fname) = shift @_;

	$self->_Debug($self->{LEVEL}{DEBUG}, "[EAFDSS::Base]::[Sign]");
	if (-e $fname) {
		$self->_Debug($self->{LEVEL}{DEBUG}, "  Signing file [%s]", $fname);
		open(FH, $fname);
		return $self->GetFullSign(*FH);
	} else {
		$self->_Debug($self->{LEVEL}{DEBUG}, "  No such file [%s]", $fname);
		return -1;
	}

	# Create A, B, C Files
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
