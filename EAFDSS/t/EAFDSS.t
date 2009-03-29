use Test::More qw(no_plan);

our($signsDir) = "/tmp/signs-testing";

BEGIN {
	print("***** NON INTERACTIVE TESTS\n\n");
	print("***** SECTION: EAFDSS\n");
	use_ok('EAFDSS'); 
}

sub createHandle {
	my($curDriver) = shift @_;
	my($dh);

	if ($curDriver eq 'Dummy') {
		$dh = new EAFDSS(
			"DRIVER" => "EAFDSS::" . $curDriver . "::/tmp/dummy.eafdss",
			"SN"     => "ABC02000001",
			"DIR"    => "/tmp/signs03",
			"DEBUG"  => 0
		);
	}

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

	SKIP: {
		skip "non interactive tests", 3 if ( ($curDriver eq 'SDSP') || ($curDriver eq 'SDNP') );

		my($dh) = createHandle($curDriver);

		ok(defined $dh, "Defined handle");
		ok($dh->isa("EAFDSS::$curDriver"),  "Loaded EAFDSS::$curDriver var");

		$result = $dh->Status();
		ok($result,  "Operation STATUS");

		$result = $dh->GetTime();
		ok($result, "Operation GET TIME");

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
	}

	rmdir($signsDir);
	print("\n");
}

