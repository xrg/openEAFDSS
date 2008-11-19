# EAFDSS - Electronic Fiscal Signature Devices Library
#          Ειδική Ασφαλής Φορολογική Διάταξη Σήμανσης (ΕΑΦΔΣΣ)
#
# Copyright (C) 2008 Hasiotis Nikos
#
# ID: $Id: Base.pm 162 2008-05-08 18:44:54Z hasiotis $

package EAFDSS;

use 5.006001;
use strict;
use warnings;
use Carp;
use Data::Dumper;

use base qw ( Class::Base );

our($VERSION) = '0.10';

sub init {
	my($self, $config) = @_;

	if (! exists $config->{DRIVER}) {
		croak "You need to provide the Driver to use";
	} else {
		$self->{DRV}    = substr($config->{DRIVER}, 0, rindex($config->{DRIVER}, "::"));
		$self->{PARAMS} = substr($config->{DRIVER}, rindex($config->{DRIVER}, "::") + 2);
		if ($self->{PARAMS} eq '') {
			croak "You need to provide params to the driver!";
		}
	}

	if (! exists $config->{DIR}) {
		croak "You need to provide the DIR to save the singatures!";
	} else {
		$self->{DIR} = $config->{DIR};
	}

	if (! -e $self->{DIR}) {
		croak "The directory to save the singatures does not exist!";
	}

	if (! exists $config->{SN}) {
		croak "You need to provide the Serial Number of the device!";
	} else {
		$self->{SN} = $config->{SN};
	}

	$self->debug("Loading driver \"$self->{DRV}\"\n");
	eval qq { require $self->{DRV} };
	if ($@) {
		return $self->error('No such driver!');
	}

	$self->debug("Initializing device with \"$self->{PARAMS}\"\n");
	my($fd) = $self->{DRV}->new(
			"PARAMS" => $self->{PARAMS},
			"SN"     => $self->{SN},
			"DIR"    => $self->{DIR},
			"DEBUG"  => $self->{_DEBUG}
		) || return $self->error('Bad constructor!');

	return $fd;
}

sub DESTROY {
	my($self) = shift;
}

# Preloaded methods go here.

1;
__END__

=head1 NAME

EAFDSS - base class for all other classes

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
