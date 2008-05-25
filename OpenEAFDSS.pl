#!/usr/bin/perl -w

use lib "EAFDSS/lib";
use strict;
use Config::IniFiles;
use Data::Dumper;
use Curses::UI;
use EAFDSS::SDNP; 


my($cfg) = Config::IniFiles->new(-file => "OpenEAFDSS.ini", -nocase => 1);
my($curDeviceID) = $cfg->val('MAIN', 'DeviceID');
my($curSignsDir) = $cfg->val('MAIN', 'SignsDir');
my($curIpAddress) = $cfg->val('MAIN', 'ipAdress');
my($curDebug) = $cfg->val('MAIN', 'Debug');

my(%reply);
my($cui) = new Curses::UI(
			-clear_on_exit  => 1,
			-color_support  => 1,
			-fg             => 'white',
			-bg             => 'blue',
		);

my($menuFile) = [
	{ -label => 'Settings   ^S', -value => \&settingsDialog  },
	{ -label => 'Exit       ^Q', -value => \&exitDialog  }
];
my($menuActions) = [
	{ -label => 'Get Status        ^U', -value => \&getStatusDialog  },
	{ -label => 'Set Headers       ^E', -value => \&setHeadersDialog  },
	{ -label => 'Get Headers       ^R', -value => \&getHeadersDialog  },
	{ -label => 'Read Time         ^T', -value => \&readTimeDialog  },
	{ -label => 'Read Device ID    ^I', -value => \&readDeviceIdDialog  },
	{ -label => 'Version Info      ^V', -value => \&versionInfoDialog  },
	{ -label => 'Display Message   ^G', -value => \&displayMessageDialog  },
];
my($menuUtilities) = [
	{ -label => 'Validate  ^V', -value => \&validateDialog  }
];
my($menuBar) = [
	{ -label => 'File',      -submenu => $menuFile },
	{ -label => 'Actions',   -submenu => $menuActions },
	{ -label => 'Utilities', -submenu => $menuUtilities}
]; 

my($menu) = $cui->add( 'menu', 'Menubar', -menu => $menuBar);

my($statusBar) = $cui->add( 'statusbar_win', 'Window', -height => 4, -y => -1);

my($status) = $statusBar->add(
	'status_text', 'TextViewer',
	-text		=> " ^X:Menu | OpenEAFDSS Demo Utility",
	-padtop		=> 2,
	-width		=> 180,
	-fg             => 'white',
	-bg             => 'blue',
);

$cui->set_binding(sub {$menu->focus()},     "\cX");
$cui->set_binding( \&settingsDialog,        "\cS");
$cui->set_binding( \&exitDialog,            "\cQ");
#$cui->set_binding( \&getStatusDialog,       "\cU");
#$cui->set_binding( \&setHeadersDialog,      "\cE");
#$cui->set_binding( \&getHeadersDialog,      "\cR");
#$cui->set_binding( \&readTimeDialog ,       "\cT");
#$cui->set_binding( \&readDeviceIdDialog ,   "\cI");
#$cui->set_binding( \&versionInfoDialog ,    "\cV");
#$cui->set_binding( \&displayMessageDialog , "\cG");

$cui->mainloop();

sub exitDialog {
	my($return) = $cui->dialog(
			-message   => "Do you really want to quit?",
			-title     => "[ Are you sure? ]", 
			-buttons   => ['yes', 'no'],
			-fg        => 'gray',
			-bg        => 'black',
			-tfg       => 'black',
			-tbg       => 'cyan',
			-bfg       => 'blue',
			-bbg       => 'black',
		);
	exit(0) if $return;
}

sub settingsDialog {
	my($winSettings) = $cui->add(
		'winSettings', 'Window',
		-width          => 60,
		-height         => 23,
		-border         => 1,
		-padtop         => 2,
		-padbottom      => 2,
		-padleft        => 2,
		-padright       => 2,
		-ipad           => 1
	);


	my($lblDeviceID) = $winSettings->add(
		"lDeviceID", "Label", -text   => "    Device ID: ",
		-x      => 2, -y      => 1,
		-height => 1, -width  => 20,
		-maxlength => 11, -textalignment => 'right',
	);
	my($txtDeviceID) = $winSettings->add(
		"DeviceID", "TextEntry", -text   => $curDeviceID,
		-fg     => 'black', -bg     => 'cyan',
		-x      => 25, -y      => 1,
		-height => 1, -width  => 12,
		-maxlength => 11,
	);

	my($lblSignaturesDir) = $winSettings->add(
		"lSignaturesDir", "Label", -text   => "Signatures Dir: ",
		-x      => 2, -y      => 3,
		-height => 1, -width  => 20,
		-maxlength => 11, -textalignment => 'right',
	);
	my($txtSignaturesDir) = $winSettings->add(
		"SignaturesDir", "TextEntry", -text   => $curSignsDir,
		-fg     => 'black', -bg     => 'cyan',
		-x      => 25, -y      => 3,
		-height => 1, -width  => 12,
		-maxlength => 11,
	);

	my($lblAddressIP) = $winSettings->add(
		"lAddressIP", "Label", -text   => "IP Address: ",
		-x      => 2, -y      => 5,
		-height => 1, -width  => 20,
		-maxlength => 11, -textalignment => 'right',
	);
	my($txtAddressIP) = $winSettings->add(
		"AddressIP", "TextEntry", -text   => $curIpAddress,
		-fg     => 'black', -bg     => 'cyan',
		-x      => 25, -y      => 5,
		-height => 1, -width  => 12,
		-maxlength => 11,
	);

	my($lblDebug) = $winSettings->add(
		"lDebug", "Label", -text   => "Debug Level: ",
		-x      => 2, -y      => 7,
		-height => 1, -width  => 20,
		-maxlength => 11, -textalignment => 'right',
	);
	my($txtDebug) = $winSettings->add(
		"Debug", "Listbox", 
		-values    => [0, 1, 2, 3, 4],
		-labels    => { 0 => 'Off', 
				1 => 'Info', 
				2 => 'Verbose', 
				3 => 'Debug',
				4 => 'Insane' },
		-selected   => $curDebug,
		-fg     => 'white', -bg     => 'black',
		-radio  => 1,
		-x      => 25, -y      => 7,
		-height => 5, -width  => 12,
		-maxlength => 11,
	);

	my($settingsCancel) = sub {
		$winSettings->loose_focus();
		$cui->delete('winSettings');
	};

	my($settingsOK) = sub {
		my($curDeviceID) = $txtDeviceID->get();
		my($curSignsDir) = $txtSignaturesDir->get();
		my($curIpAddress) = $txtAddressIP->get(); 
		my($curDebug) = $txtDebug->get(); 

		$cfg->setval("MAIN", 'DeviceID', $curDeviceID);
		$cfg->setval("MAIN", 'SignsDir', $curSignsDir);
		$cfg->setval("MAIN", 'ipAdress', $curIpAddress);
		$cfg->setval("MAIN", 'Debug', $curDebug);
		$cfg->RewriteConfig();

		$winSettings->loose_focus();
		$cui->delete('winSettings');
	};

	my($btnBox) = $winSettings->add(
		"btnBox", "Buttonbox" ,
		-y => -1,
		-buttons => [
			{ -label    => '< OK >',
			  -shortcut => 'o',
			  -value    => 1,
			  -onpress  => $settingsOK },
			{ -label    => '< Cancel >',
			  -shortcut => 'c',
			  -value    => 0,
			  -onpress  => $settingsCancel}
		],
		-buttonalignment => 'middle'
	);

	$btnBox->focus();
	$winSettings->modalfocus();
}


sub getStatusDialog {
	my($FD) = new EAFDSS::SDNP(DIR => "/tmp/SIGNS", SN => "ABC02000001", IP => "miles");
	%reply = $FD->GetStatus();
	$cui->dialog(
		-title => "Device Status",
		-message => sprintf("[%s]    ", $reply{DATA})
	);
}

sub setHeadersDialog {
	my($FD) = new EAFDSS::SDNP(DIR => "/tmp/SIGNS", SN => "ABC02000001", IP => "miles");
	%reply = $FD->SetHeader();
	$cui->dialog(
		-title => "Set Headers",
		-message => sprintf("[%s]    ", $reply{DATA})
	);
}

sub getHeadersDialog {
	my($FD) = new EAFDSS::SDNP(DIR => "/tmp/SIGNS", SN => "ABC02000001", IP => "miles");
	%reply = $FD->GetHeader();
	$cui->dialog(
		-title => "Get Headers",
		-message => sprintf("[%s]    ", $reply{DATA})
	);
}

sub readTimeDialog {
	my($FD) = new EAFDSS::SDNP(DIR => "/tmp/SIGNS", SN => "ABC02000001", IP => "miles");
	%reply = $FD->ReadTime();
	$cui->dialog(
		-title => "Device Time",
		-message => sprintf("[%s]    ", $reply{DATA})
	);
}

sub readDeviceIdDialog {
	my($FD) = new EAFDSS::SDNP(DIR => "/tmp/SIGNS", SN => "ABC02000001", IP => "miles");
	%reply = $FD->ReadDeviceID();
	$cui->dialog(
		-title => "Device ID",
		-message => sprintf("[%s]    ", $reply{DATA})
	);
}

sub versionInfoDialog {
	my($FD) = new EAFDSS::SDNP(DIR => "/tmp/SIGNS", SN => "ABC02000001", IP => "miles");
	%reply = $FD->VersionInfo();
	$cui->dialog(
		-title => "Device Version",
		-message => sprintf("[%s]    ", $reply{DATA})
	);
}

sub displayMessageDialog {
	my($FD) = new EAFDSS::SDNP(DIR => "/tmp/SIGNS", SN => "ABC02000001", IP => "miles");
	%reply = $FD->DisplayMessage("Hallo mitso");
	$cui->dialog(
		-title => "Device Message",
		-message => sprintf("[%s]    ", $reply{DATA})
	);
}
