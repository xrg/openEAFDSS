#!/usr/bin/perl -w

#use lib "EAFDSS/lib";
use EAFDSS::SDNP; 

my($FD) = new EAFDSS::SDNP(
		DIR   => "/tmp/SIGNS",
		SN    => "ABC02000001",
		IP    => "127.0.0.1",
		#DEBUG => 3
	);

printf("  SIGN -->[%s]\n", $FD->Sign("invoice.txt"));

