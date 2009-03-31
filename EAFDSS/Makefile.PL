use 5.006001;
use strict;
use warnings;
use Data::Dumper;
use ExtUtils::MakeMaker qw( WriteMakefile prompt );

my(%config) = (
    NAME              => 'EAFDSS',
    VERSION_FROM      => 'lib/EAFDSS.pm',
    license( 'perl' ),
    PREREQ_PM         => {
		"Switch"             => 2.10,
		"Carp"               => 1.04,
		"Socket"             => 1.78,
		"Class::Base"        => 0.03,
		"IO::Socket::INET"   => 1.31,
		"Digest::SHA1"       => 2.11,
		"Config::IniFiles"   => 2.38,
		"Device::SerialPort" => 1.00
	 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/EAFDSS.pm', # retrieve abstract from module
       AUTHOR         => 'Hasiotis Nikos (hasiotis@gmail.com)') : ()),
);

sub license {
	my($lic) = shift @_;
	local $^W = 0; 
	return
		unless $ExtUtils::MakeMaker::VERSION >= '6.31';
	return ( LICENSE => $lic );
}

WriteMakefile(%config);

