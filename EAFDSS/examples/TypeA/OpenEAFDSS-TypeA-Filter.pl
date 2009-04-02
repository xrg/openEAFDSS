#!/usr/bin/perl -w

# OpenEAFDSS-TypeA-Filter.pl 
#	Electronic Fiscal Signature Devices CUPS Filter
#       Ειδική Ασφαλής Φορολογική Διάταξη Σήμανσης (ΕΑΦΔΣΣ)
#
# Copyright (C) 2008 by Hasiotis Nikos
#
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# ID: $Id: OpenEAFDSS.pl 73 2009-04-02 00:17:46Z hasiotis $

use strict;
use EAFDSS; 
use DBI;
use Data::Dumper;
use Config::IniFiles;

my(%progie) = ( name      => 'OpenEAFDSS-TypeA-Filter.pl',
                author    => 'Nikos Hasiotis (hasiotis@gmail.com)',
                copyright => 'Copyright (c) 2008 Hasiotis Nikos, all rights reserved',
                version   => '0.40');

our($debug) = 1;

sub main {
	my($job_id, $user, $job_name, $copies, $options, $fname, $sandbox);

	$sandbox = sprintf("%s/OpenEAFDSS-TMP-%s", $ENV{'TMPDIR'}, $$);
	if ($#ARGV < 5) {
		umask(077);
		if (! mkdir($sandbox) ) {
			printf(STDERR "ERROR: [OpenEAFDSS] Cannot create temporary directory [%s]! Exiting\n", $sandbox);
			exit 1;
		}
		$fname = sprintf("%s/JOB-TEMP-FILE-01", $sandbox); 
		printf(STDERR "NOTICE: [OpenEAFDSS] (STDIN) Signing file [%s]\n", $fname);
	} else {
		($job_id, $user, $job_name, $copies, $options, $fname) = @ARGV;
		printf(STDERR "NOTICE: [OpenEAFDSS] Signing file [%s]\n", $fname);
	}

	my($cfg) = Config::IniFiles->new(-file => "/etc/OpenEAFDSS/OpenEAFDSS-TypeA.ini", -nocase => 1);

	my($ABC_DIR) = $cfg->val('MAIN', 'ABC_DIR', '/tmp/signs');
	my($SQLITE)  = $cfg->val('MAIN', 'SQLITE', '/tmp/eafdss.sqlite');

	my($SN)      = $cfg->val('DEVICE', 'SN', 'ABC02000001');
	my($DRIVER)  = $cfg->val('DEVICE', 'DRIVER', 'SDNP');
	my($PARAM)   = $cfg->val('DEVICE', 'PARAM', 'localhost');

	my($dh) = new EAFDSS(
			"DRIVER" => "EAFDSS::" . $DRIVER . "::" . $PARAM,
			"SN"     => $SN,
			"DIR"    => $ABC_DIR,
			"DEBUG"  => $debug
		);

	if (! $dh) {
		print(STDERR "ERROR: [OpenEAFDSS]" . EAFDSS->error() ."\n");
		exit 1;
	}
  
	my($signature) = $dh->Sign($fname);
	if (! $signature) {
		my($errNo)  = $dh->error();
		my($errMsg) = $dh->errMessage($errNo);
		printf(STDERR "ERROR: [OpenEAFDSS] [0x%02X] %s\n", $errNo, $errMsg);
		exit($errNo);
	} else {
		printf(STDERR "NOTICE: [OpenEAFDSS] Got sign [%s]\n", $signature);
	}

	open(FH, "<", $fname) || exit;
	while (<FH>) {
		print $_;
	};
	close(FH);

	printf(" %s \n", $signature);

	rmdir($sandbox);
}

main();
exit;
