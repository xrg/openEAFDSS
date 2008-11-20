use Test::More qw(no_plan);

BEGIN { use_ok( 'EAFDSS' ); }

sub createHandle {
	my($curDriver) = shift @_;

	my($dh);

	if ($curDriver eq 'SDNP') {
		$dh = new EAFDSS(
			"DRIVER" => "EAFDSS::" . $curDriver . "::miles",
			"SN"     => "ABC02000001",
			"DIR"    => "/tmp/signs01",
			"DEBUG"  => 0
		);
	}
	if ($curDriver eq 'Dummy') {
		$dh = new EAFDSS(
			"DRIVER" => "EAFDSS::" . $curDriver . "::/tmp/dummy.eafdss",
			"SN"     => "ABC02000001",
			"DIR"    => "/tmp/signs02",
			"DEBUG"  => 0
		);
	}

	return $dh;
}


my(@drivers) = EAFDSS->available_drivers;
ok(@drivers,  "Found drivers");

my($curDriver);
foreach $curDriver (@drivers) {
	my($result);
	my($dh) = createHandle($curDriver);

	ok(defined $dh, "Defined handle");
	ok($dh->isa("EAFDSS::$curDriver"),  "Loaded EAFDSS::$curDriver var");

	$result = $dh->Status();
	ok($result,  "Operation STATUS");

	$result = $dh->GetTime();
	ok($result, "Operation GET TIME");

	SKIP: {
		skip "Set Time, Get/Set Headers not working on Dummy driver", 3 if ($curDriver eq 'Dummy');

		$result = $dh->SetTime('131211/232425/');
		is($result, 0, "Operation SET TIME");
		sleep 2;

		$result = $dh->GetHeaders();
		ok($result, "Operation GET HEADERS");
		sleep 3;

		$result = $dh->SetHeaders("0/H01/0/H02/0/H03/0/H04/0/H05/0/H06/");
		is($result, 0, "Operation SET HEADERS");
		sleep 2;
	}

	$result = $dh->Info();
	ok($result, "Operation INFO");

	$result = $dh->Sign("/tmp/invoice.txt");
	ok($result, "Operation SIGN");
	sleep 2;

	$result = $dh->Report();
	ok($result, "Operation REPORT");

}

