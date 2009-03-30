use Test::More qw(no_plan);
use EAFDSS;

my($sdir)    = "/tmp/signs-testing";
my($sn)      = 'ABC02000001';
my($prm)     = '/tmp/dummy.eafdss';
my($invoice) = "/tmp/invoice.txt";

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

$result = $dh->GetTime();
ok($result, "Operation GET TIME");

$result = $dh->Info();
ok($result, "Operation INFO");

open(INVOICE, ">> $invoice");
print(INVOICE "TEST OpenEAFDSS invoice Document\n");
close(INVOICE); 

$result = $dh->Sign($invoice);
ok($result, "Operation SIGN");

unlink($invoice);

$result = $dh->Report();
ok($result, "Operation REPORT");

rmdir($sdir);

exit;
