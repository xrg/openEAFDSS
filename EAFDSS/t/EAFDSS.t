use Test::More qw(no_plan);

BEGIN {
	use_ok('EAFDSS'); 
}

our($signsDir) = "/tmp/signs-testing";
our($tmp_invoice) = "/tmp/invoice.txt";

unlink($tmp_invoice);
rmdir($signsDir);
mkdir($signsDir);

my(@drivers) = EAFDSS->available_drivers();
ok(@drivers,  "Found drivers");

my($dh) = new EAFDSS(
		"DRIVER" => "EAFDSS::Dummy::/tmp/dummy.eafdss",
		"SN"     => "ABC02000001",
		"DIR"    => $signsDir,
		"DEBUG"  => 0
	);
ok(defined $dh, "Defined EAFDSS driver handle");
ok($dh->isa("EAFDSS::Dummy"),  "Loaded EAFDSS::Dummy driver");

my($result);

$result = $dh->Status();
ok($result,  "Operation STATUS");

$result = $dh->GetTime();
ok($result, "Operation GET TIME");

$result = $dh->Info();
ok($result, "Operation INFO");

open(INVOICE, ">> $tmp_invoice");
print(INVOICE "TEST OpenEAFDSS invoice Document\n");
close(INVOICE); 

$result = $dh->Sign($tmp_invoice);
ok($result, "Operation SIGN");
	
unlink($tmp_invoice);

$result = $dh->Report();
ok($result, "Operation REPORT");

rmdir($signsDir);
