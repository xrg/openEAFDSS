#!/usr/bin/perl -w

use strict;
use lib "EAFDSS/lib";
use EAFDSS::Base; 
use Getopt::Std;
use Data::Dumper; 
use Config::General qw(ParseConfig);

my($verbal) = "FALSE";
my(%progie) = ( name      => 'OpenEAFDSS-Util.pl',
                author    => 'Nikos Hasiotis (hasiotis@gmail.com)',
                copyright => 'Copyright (c) 2008 Hasiotis Nikos, all rights reserved',
                version   => '0.10');

sub main() {
        my($driver, $params, $serial, $sDir, $cmd, $file) = init_progie();

	#my($fd) = new EAFDSS($driver . "::" . $params, $serial, $sDir);
	#if ($fd) {
	#} else {
	#	printf("Could not initialize signature device...\n");
	#}
	
}

sub init_progie() {
        my(%opt, $valid, $cfg, $name, $cmd, $driver, $serial, $params, $sDir, $file);
        getopts('hvn:d:s:p:i:e:f:c:', \%opt);

        if ($opt{c}) {$cfg    = $opt{i}}  else {$cfg = "OpenEAFDSS-Util.conf"}
	my(%cfg) = ParseConfig(-ConfigFile => $cfg, -LowerCaseNames => 1);

        if ($opt{h}) {$valid  = "FALSE"}  else {$valid  = "TRUE"};
        if ($opt{v}) {$verbal = "TRUE"}   else {$verbal = "FALSE"};

        if ($opt{n}) {$name   = $opt{n}}  else {$valid = "FALSE"};
	if ($valid ne "FALSE") {
		$name = lc($name);
		$driver = $cfg{$name}{"driver"};
		$serial = $cfg{$name}{"sn"};
		$params = $cfg{$name}{"parameters"};
	        $sDir   = $cfg{$name}{"dir"};
	}

        if ($opt{e}) {$cmd    = $opt{e}}  else {$valid = "FALSE"};

        if ($opt{d}) {$driver = $opt{d}};
        if ($opt{s}) {$serial = $opt{s}};
        if ($opt{p}) {$params = $opt{p}};
        if ($opt{i}) {$sDir   = $opt{i}};

        if ($opt{f}) {$file   = $opt{f}};

        if ($valid =~ /FALSE/) {
		print_help();
                exit(0);
        } else {
                return($driver, $params, $serial, $sDir, $cmd, $file);
        }
}

sub print_help() {
	printf("\n$progie{name} (ver $progie{version}) -- $progie{copyright}\n");
	printf("\n  How to use $progie{name} ...\n\n");
	printf("\t  -h                 [this help screen]\n");
	printf("\t  -v                 [verbose level]\n");
	printf("\t  -n                 [Name of device on config file]\n");
	printf("\t  -d                 [driver to use]\n");
	printf("\t  -s                 [device serial number]\n");
	printf("\t  -p                 [driver parameters]\n");
	printf("\t  -i                 [signs directory]\n");
	printf("\t  -e                 [command to execute (SIGN, DATE, TIME, STATUS)]\n");
	printf("\t  -f                 [file to sign]\n");
	printf("\t  -c <config file>   [which config file to use (default: OpenEAFDSS-Util.conf)]\n");
	printf("\n  Example 1: $progie{name} -d EAFDSS::SDNP -p hostname -e SIGN -f invoice.txt\n");
	printf("\n             This command will sign the file invoice.txt printing the signature");
	printf("\n             on the stdout.\n\n");
	printf("\n  Example 2: $progie{name} -n DEV-NAME -e STATUS\n");
	printf("\n             This command will print the status of the device marked by DEV-NAME");
	printf("\n             on the configuration file.\n\n");
}

main();
exit;
