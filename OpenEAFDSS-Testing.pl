#!/usr/bin/perl -w

use lib "EAFDSS/lib";
use EAFDSS::SDNP; 
use Digest::SHA1  qw(sha1_hex);
use Data::Dumper;

my($FD) = new EAFDSS::SDNP(
		DIR   => "/tmp/SIGNS",
		SN    => "ABC02000001",
		IP    => "miles",
		#DEBUG => 3
	);

my($totalSigns, $dailySigns, $date, $time, $sign) = $FD->Sign("invoice.txt");
printf("    SIGN --> [%s]\n", $sign);

$data = "";
open(FILE, 'invoice.txt') or die $!;
foreach (<FILE>) {
	$data .= $_; 
}

$date =~ s/(\d\d)(\d\d)(\d\d)/$3$2$1/;
$time =~ s/(\d\d)(\d\d)(\d\d)/$1$2/;
$extra_data .= sprintf("ABC02000001%08d%04d%s%s", $totalSigns, $dailySigns, $date, $time);
$data .= $extra_data;

printf("  VERIFY --> [%s]\n", uc(sha1_hex($data)));


