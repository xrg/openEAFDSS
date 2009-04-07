use strict;
use warnings;
use Test::More qw(no_plan);
use File::Path;
use Data::Dumper;
use EAFDSS;

my($sdir)    = "./signs-testing";
my($sn)      = 'ABC02000001';
my($prm)     = './dummy.eafdss';
my($invoice) = "./invoice.txt";

rmdir($sdir);
mkdir($sdir);

my($dh) = new EAFDSS(
	"DRIVER" => sprintf("EAFDSS::Dummy::%s", $prm),
	"SN"     => $sn,
	"DIR"    => $sdir,
	"DEBUG"  => 0
);

ok(defined $dh, "Defined handle");
ok($dh->isa("EAFDSS::Dummy"),  "Initialized EAFDSS::Dummy device");

my($result);
$result = $dh->Status();
ok($result,  "Operation STATUS");

$result = $dh->Report();
ok($result, "Operation REPORT");

$result = $dh->GetTime();
ok($result, "Operation GET TIME");

$result = $dh->Info();
ok($result, "Operation INFO");

open(INVOICE, ">> $invoice");
print(INVOICE "TEST OpenEAFDSS invoice Document\n");
close(INVOICE); 

$result = $dh->Sign($invoice);
ok($result, "Operation SIGN");

## Check recreation of B files
# Init device
unlink($prm);
$dh = new EAFDSS(
	"DRIVER" => sprintf("EAFDSS::Dummy::%s", $prm),
	"SN"     => $sn,
	"DIR"    => $sdir,
	"DEBUG"  => 0
);
# Empty signs dir
rmtree($sdir);
# Sign a File
$result = $dh->Sign($invoice);
# Delete the b file
opendir(DIR, "$sdir/$sn");
grep { /_b.txt/ && unlink("$sdir/$sn/$_") } readdir(DIR);
closedir DIR;
# Issue a Z report
$dh->Report();
# check that there is one A file, one B file, one C file in dir
opendir(DIR, "$sdir/$sn");
my(@b) = grep { /_b.txt/ && unlink("$sdir/$sn/$_") } readdir(DIR);
closedir DIR;
ok(@b, "B Files recreation");

## Check recreation of C files
# Init device
# Empty signs dir
# Issue a Z report
# check that there is one A file, one B file, one C file in dir
# Empty signs dir
# Issue a Z report
# check that there are 2 C files in dir

## check recovery handling
# Init device
# Empty signs dir
# Sign a File
# Force CMOS error
# Sign a File
# check that there is one A file, one B file with two signatures in it, one C file in dir

unlink($invoice);
unlink($prm);

rmtree($sdir);

exit;
