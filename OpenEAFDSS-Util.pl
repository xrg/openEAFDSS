#!/usr/bin/perl -w

use strict;
use lib "EAFDSS/lib";
use Switch;
use EAFDSS; 
use Getopt::Std;
use Data::Dumper; 
use Config::General qw(ParseConfig);

my(%progie) = ( name      => 'OpenEAFDSS-Util.pl',
                author    => 'Nikos Hasiotis (hasiotis@gmail.com)',
                copyright => 'Copyright (c) 2008 Hasiotis Nikos, all rights reserved',
                version   => '0.10');

sub main() {
        my($verbal, $driver, $params, $serial, $sDir, $cmd) = init_progie();
	
	my($dh) = new EAFDSS(
			"DRIVER" => $driver . "::" . $params,
			"SN"     => $serial,
			"DIR"    => $sDir,
			"DEBUG"  => $verbal
		) || print("ERROR: " . EAFDSS->error() ."\n");

	my($cmdType, $cmdParam) = split(/\s+/, $cmd);

	switch (uc($cmdType)) {
		case "SIGN"    { cmdSign($dh, $cmdParam)    }
		case "STATUS"  { cmdStatus($dh)             }
		case "TIME"    { cmdTime($dh, $cmdParam)    }
		case "REPORT"  { cmdReport($dh)             }
		case "INFO"    { cmdInfo($dh)               }
		case "HEADERS" { cmdHeaders($dh, $cmdParam) }
	}
}

sub cmdSign() {
	my($dh)    = shift @_;
	my($fname) = shift @_;

	my($result) = $dh->Sign($fname) || die("ERROR: " . $dh->error() ."\n");

	printf("%s\n", $result);
}

sub cmdStatus() {
	my($dh)    = shift @_;

	my($result) = $dh->Status() || die("ERROR: " . $dh->error() ."\n");

	printf("%s\n", $result);
}

sub cmdTime() {
	my($dh)    = shift @_;
	my($time)  = shift @_;

	my($result) = $dh->Time() || die("ERROR: " . $dh->error() ."\n");

	printf("%s\n", $result);
}

sub cmdReport() {
	my($dh)    = shift @_;

	my($result) = $dh->Report() || die("ERROR: " . $dh->error() ."\n");

	printf("%s\n", $result);
}

sub cmdInfo() {
	my($dh)    = shift @_;

	my($result) = $dh->Info() || die("ERROR: " . $dh->error() ."\n");

	printf("%s\n", $result);
}

sub cmdHeaders() {
	my($dh)      = shift @_;
	my($headers) = shift @_;

	my($result) = $dh->Headers() || die("ERROR: " . $dh->error() ."\n");

	printf("%s\n", $result);
}

sub init_progie() {
        my(%opt, $valid, $cfg, $name, $cmd, $debug, $driver, $serial, $params, $sDir);
        getopts('hvn:d:s:p:i:e:c:', \%opt);

        if ($opt{c}) {$cfg    = $opt{i}}  else {$cfg = "OpenEAFDSS-Util.conf"}
	my(%cfg) = ParseConfig(-ConfigFile => $cfg, -LowerCaseNames => 1);

        if ($opt{h}) {$valid  = "FALSE"}  else {$valid = "TRUE"};
        if ($opt{v}) {$debug  = 1      }  else {$debug = 0     };

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

        if ($valid =~ /FALSE/) {
		print_help();
                exit(0);
        } else {
                return($debug, $driver, $params, $serial, $sDir, $cmd);
        }
}

sub print_help() {
	printf("\n$progie{name} (ver $progie{version}) -- $progie{copyright}\n");
	printf("\n  How to use $progie{name} ...\n\n");
	printf("\t  -h                                (this help screen)              \n");
	printf("\t  -v                                (enable debug information)      \n\n");
	printf("\t  -c CONFIG_FILENAME                (which config file to use       \n");
	printf("\t                                     default: OpenEAFDSS-Util.conf) \n\n");
	printf("\t  -n DEVICE_NAME                    (device name on config file)    \n");
	printf("\t  -d DRIVER_NAME                    (driver to use)                 \n");
	printf("\t  -s SERIAL_NUMBER                  (device serial number)          \n");
	printf("\t  -p DRIVER_PARAMETERS              (driver parameters)             \n\n");
	printf("\t  -i DIRECTORY                      (signs directory)               \n");
	printf("\t  -e \"COMMAND [COMMAND_PARAM]\"      (command to execute:          \n");
	printf("\t                                         - SIGN [filename]          \n");
	printf("\t                                         - TIME [time]              \n");
	printf("\t                                         - STATUS                   \n");
	printf("\t                                         - REPORT                   \n");
	printf("\t                                         - INFO                     \n");
	printf("\t                                         - HEADERS [headers])       \n");
	printf("\n  Example 1: $progie{name} -d EAFDSS::SDNP -p hostname -e \"SIGN invoice.txt\"\n");
	printf("\n             This command will sign the file invoice.txt printing the signature");
	printf("\n             on the stdout.\n\n");
	printf("\n  Example 2: $progie{name} -n DEV-NAME -e STATUS\n");
	printf("\n             This command will print the status of the device marked by DEV-NAME");
	printf("\n             on the configuration file.\n\n");
}

main();
exit;
