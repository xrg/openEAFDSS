# EAFDSS - Electronic Fiscal Signature Devices Library
#          Ειδική Ασφαλής Φορολογική Διάταξη Σήμανσης (ΕΑΦΔΣΣ)
#
# Copyright (C) 2008 Hasiotis Nikos
#
# ID: $Id$

package EAFDSS;

use 5.006001;
use strict;
use warnings;
use Carp;
use Class::Base;
use Data::Dumper;

use base qw ( Class::Base );

our($VERSION) = '0.13';

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

sub available_drivers {
	my(@drivers, $curDir, $curFile, $curDirEAFDSS);

	foreach $curDir (@INC){
		$curDirEAFDSS = $curDir . "/EAFDSS";
		next unless -d $curDirEAFDSS;

		opendir(DIR, $curDirEAFDSS) || carp "opendir $curDirEAFDSS: $!\n";
		foreach $curFile (readdir(EAFDSS::DIR)){
			next unless $curFile =~ s/\.pm$//;
			next if $curFile eq 'Base';
			next if $curFile eq 'Micrelec';
			push(@drivers, $curFile);
		}
		closedir(DIR);
	}

	return @drivers;
}


sub DESTROY {
	my($self) = shift;
}

# Preloaded methods go here.

1;
__END__

=head1 NAME

EAFDSS - Electronic Fiscal Signature Devices Library

=head1 SYNOPSIS

  use EAFDSS; 

  $dh = new EAFDSS(
  	"DRIVER" => "$driver::$params",
	"SN"     => $serial,
	"DIR"    => $sDir,
	"DEBUG"  => $verbal
     );


  $result = $dh->Status();
  $result = $dh->Sign($fname);
  $result = $dh->Info();
  $result = $dh->SetTime($time);
  $result = $dh->GetTime();
  $result = $dh->SetHeaders($headers);
  $result = $dh->GetHeaders();


=head1 DESCRIPTION

The EAFDSS module handles the communication with an Electronic Signature Device (EAFDSS).
It defines a set of methods common to all EAFDSS devices in order to communicate with the
device but also handle all necessary file housekeeping requirements by Law, like creating
A, B, C files.

=head1 ARCHITECTURE

This module is loosely (and shamelessly I may add) influenced by the architecture of the
DBI module. There is a layer of a basic API that is common to all EAFDSS device drivers.
Usually a developer of an EAFDSS application will only need to deal with functions only
at that level. You have to be in need of something really special to access functions
that are specific to a certain driver.

=head1 Methods

** INCOMPLETE **

=head2 EAFDSS->new("DRIVER" => "$driver::$params", "SN" => $serial, "DIR" => $sDir, "DEBUG" => $verbal);

Returns a newly created $driver object. The DRIVER argument is a compination of a driver and
it's parameters. For instance it could be one of the following:

  EAFDSS::SDNP::127.0.0.1

or
 
  EAFDSS::Dummy:/tmp/dummy.eafdss

The SN argument is the Serial number of device we wan't to connect. Each device has it's own unique serial
number. If the device's SN does not much with the provided then you will get an error.

The DIR argument is the directory were the signature files (A, B and C) will be created. Make sure the 
directory exist.

The last argument is the DEBUG. Use a true value in order to get additional information. This one is only 
useful to developers of the module itself.

=head2 $dh->Sign($filename)

That method will provide the contents of the file $filename to the EAFDSS and return it's signature.

=head2 $dh->Info

Get info about the device

=head2 $dh->SetTime

Set the time on the device

=head2 $dh->GetTime

Get the time of the device

=head2 $dh->SetHeaders

Set the headers

=head2 $dh->GetHeaders

Get the headers

=head1 VERSION

This is version 0.13. Which actually is the first release and an unstable release. Only for beta testers!

=head1 AUTHOR

Hasiotis Nikos, E<lt>hasiotis@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Hasiotis Nikos

This library is free software; you can redistribute it and/or modify
it under the terms of the LGPL or the same terms as Perl itself,
either Perl version 5.8.8 or, at your option, any later version of
Perl 5 you may have available.

=cut
