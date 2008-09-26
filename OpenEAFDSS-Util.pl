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

	my($fd) = new EAFDSS($driver . "::" . $params, $serial, $sDir);
	
	#my($fd) = new EAFDSS("EAFDSS::SDNP::gattaca-wlan,24830", "ABC02000001", "/tmp/signs");
	#my($fd) = new EAFDSS("EAFDSS::SDSP::/dev/ttyS0,38400", "ABC02000001", "/tmp/signs");
	#my($fd) = new EAFDSS("EAFDSS::Dummy::/tmp/dummy-sd", "ABC02000001", "/tmp/signs");

	my($reply, $sign) = $fd->Sign("invoice.txt");
	printf("    SIGN --> [%s]\n", $sign);
}

sub init_progie() {
        my(%opt, $valid, $cfg, $cmd, $driver, $serial, $params, $sDir, $file);
        getopts('hvn:d:s:p:i:e:f:c:', \%opt);

        if ($opt{c}) {$cfg    = $opt{i}}  else {$cfg = "OpenEAFDSS-Util.conf"}
	my(%cfg) = ParseConfig($cfg);

	print Dumper $cfg{'LAN'};
	exit;

        if ($opt{h}) {$valid  = "FALSE"}  else {$valid  = "TRUE"};
        if ($opt{v}) {$verbal = "TRUE"}   else {$verbal = "FALSE"};
        if ($opt{e}) {$cmd    = $opt{e}}   else {$valid = "FALSE"};
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
	printf("\n  Example: $progie{name} -d EAFDSS::SDNP -p gattaca-wlan -e SIGN -f invoice.txt\n");
	printf("\n           This command will sign the file invoice.txt printing the signature");
	printf("\n           on the stdout.\n\n");
}

main();
exit;
