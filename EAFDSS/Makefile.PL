use 5.006001;
use strict;
use warnings;
use Data::Dumper;
use POSIX qw/getpgrp tcgetpgrp/;
use ExtUtils::MakeMaker qw( WriteMakefile prompt );

sub isInteractive () {
	if (!open(TTY, "/dev/tty")) {
		return 0;
	} else {
		my($tpgrp) = tcgetpgrp(fileno(*TTY));
		my($pgrp) = getpgrp();
		if ($tpgrp == $pgrp) {
			return 1;
		} else {
			return 0;
		}
	}
}

my(%config) = (
    NAME              => 'EAFDSS',
    VERSION_FROM      => 'lib/EAFDSS.pm',
    PREREQ_PM         => {
		"Switch"             => 2.10,
		"Carp"               => 1.04,
		"Socket"             => 1.78,
		"Class::Base"        => 0.03,
		"IO::Socket::INET"   => 1.31,
		"Digest::SHA1"       => 2.11,
		"Config::IniHash"    => 3.00,
		"Device::SerialPort" => 1.00
	 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/EAFDSS.pm', # retrieve abstract from module
       AUTHOR         => 'Hasiotis Nikos (hasiotis@gmail.com)') : ()),
);

my(@test_files);

if ( isInteractive() ) {
	print "==> Running the interactive test requires the relevant emulator! <==\n";
	my($reply) = prompt('Do you want to run the extended test suite?', 'no');

	if ($reply =~ /^y/i ) {
		print "I'm going to run the interactive tests.\n";
		push @test_files, 't/interactive/*.t';
	} else {
		push @test_files, 't/*.t';
		print "Skipping interactive tests.\n";
	}
}

$config{test} = { TESTS => join ' ', map { glob } @test_files};

WriteMakefile(%config);

