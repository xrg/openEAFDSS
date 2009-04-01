use 5.006001;
use strict;
use warnings;
use ExtUtils::MakeMaker qw( WriteMakefile prompt );

my(%config) = (
	NAME		=> 'EAFDSS',
	VERSION_FROM	=> 'lib/EAFDSS.pm',
	LICENSE		=> 'lgpl',
	ABSTRACT_FROM	=> 'lib/EAFDSS.pm',
	AUTHOR		=> 'Hasiotis Nikos (hasiotis@gmail.com)',
	PREREQ_PM	=> {
		"Switch"            => 2.10,
		"Carp"              => 1.04,
		"Socket"            => 1.78,
		"Class::Base"       => 0.03,
		"IO::Socket::INET"  => 1.31,
		"Digest::SHA1"      => 2.11,
		"Config::IniFiles"  => 2.38,
	}
);

WriteMakefile(%config);

