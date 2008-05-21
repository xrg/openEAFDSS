#!/usr/bin/perl -w

use lib "EAFDSS/lib";
use EAFDSS::SDNP; 
use Data::Dumper;

my($FD) = new EAFDSS::SDNP(
		DIR   => "/tmp/SIGNS",
		SN    => "ABC02000001",
		IP    => "miles",
		#DEBUG => 3
	);

#printf("           SIGN --> [%s]\n", $FD->Sign("invoice.txt"));

my(%x) = $FD->GetStatus();
printf("         STATUS --> [%s]\n", $x{DATA});

%x = $FD->SetHeader();
printf("     SET HEADER --> [%s]\n", $x{DATA});

#%x = $FD->GetHeader();
#printf("     GET HEADER --> [%s]\n", $x{DATA});

%x = $FD->ReadTime();
printf("      Read TIME --> [%s]\n", $x{DATA});

%x = $FD->ReadDeviceID();
printf(" Read Device ID --> [%s]\n", $x{DATA});

%x = $FD->VersionInfo();
printf("   Version Info --> [%s]\n", $x{DATA});

%x = $FD->DisplayMessage("Hallo");
printf("Display Message --> [%s]\n", $x{DATA});

