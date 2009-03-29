use ExtUtils::MakeMaker qw( prompt );
use Test::More qw(no_plan);

BEGIN {
	print("***** INTERACTIVE TESTS\n\n");
	print("***** SECTION: EAFDSS\n");
	use_ok('EAFDSS'); 
}

sub createHandle {
	my($curDriver) = shift @_;

	my($signsDir) = "/tmp/signs-testing";

	rmdir($signsDir);
	mkdir($signsDir);

	my($dh, $sn, $prm);

	if ($curDriver eq 'SDNP') {
		printf("Connect the emulator with the network interface!\n");
		$sn  = prompt('  Emulator serial number: ', 'ABC02000001');
		$prm = prompt('  IP or hostname of emulator:', 'miles');
	}

	if ($curDriver eq 'SDSP') {
		printf("Connect the emulator with the serial interface!\n");
		$sn  = prompt('  Emulator serial number: ', 'ABC02000001');
		$prm = prompt('  Serial port device name:', '/dev/ttyS0');
	}

	if ($curDriver eq 'Dummy') {
		$sn  = 'ABC02000001';
		$prm = '/tmp/dummy.eafdss';
	}

	print("\n");

	$dh = new EAFDSS(
		"DRIVER" => sprintf("EAFDSS::%s::%s", $curDriver, $prm),
		"SN"     => $sn,
		"DIR"    => $signsDir,
		"DEBUG"  => 0
	);

	return $dh;
}

my(@drivers) = EAFDSS->available_drivers();
ok(@drivers,  "Found drivers");
print("\n");

my($curDriver);
foreach $curDriver (@drivers) {
	rmdir($signsDir);
	mkdir($signsDir);

	my($result);
	print("***** SECTION: $curDriver Module\n");

	my($dh) = createHandle($curDriver);

	ok(defined $dh, "Defined handle");
	ok($dh->isa("EAFDSS::$curDriver"),  "Initialized EAFDSS::$curDriver device");

	$result = $dh->Status();
	ok($result,  "Operation STATUS");

	$result = $dh->GetTime();
	ok($result, "Operation GET TIME");

	SKIP: {
		skip "Set Time, Get/Set Headers not working on Dummy driver", 3 if ($curDriver eq 'Dummy');

		$result = $dh->SetTime('29/03/09 12:45:57');
		is($result, 0, "Operation SET TIME");
		sleep 2;

		$result = $dh->GetHeaders();
		ok($result, "Operation GET HEADERS");
		sleep 3;

		$result = $dh->SetHeaders("0/H01/0/H02/0/H03/0/H04/0/H05/0/H06");
		is($result, 0, "Operation SET HEADERS");
		sleep 2;
	}

	$result = $dh->Info();
	ok($result, "Operation INFO");

	my($tmp_invoice) = "/tmp/invoice.txt";
	open(INVOICE, ">> $tmp_invoice");
	print(INVOICE "TEST OpenEAFDSS invoice Document\n");
	close(INVOICE); 

	$result = $dh->Sign($tmp_invoice);
	ok($result, "Operation SIGN");

	unlink($tmp_invoice);

	$result = $dh->Report();
	ok($result, "Operation REPORT");

	rmdir($signsDir);
	print("\n");

	exit;
}

