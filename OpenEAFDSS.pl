#!/usr/bin/perl -w

use lib "EAFDSS/lib";
use Curses::UI;
use EAFDSS::SDNP; 

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
my($menuBar) = [
	{ -label => 'File',    -submenu => $menuFile },
	{ -label => 'Actions', -submenu => $menuActions }
]; 

my($menu) = $cui->add( 'menu', 'Menubar', -menu => $menuBar);

my($statusBar) = $cui->add( 'statusbar_win', 'Window', -height => 4, -y => -1);

my($status) = $statusBar->add(
	'status_text', 'TextViewer',
	-padtop		=> 2,
	-width		=> 180,
	-text		=> " OpenEAFDSS Demo Utility",
	-fg             => 'white',
	-bg             => 'blue',
);

$cui->set_binding(sub {$menu->focus()},     "\cX");
$cui->set_binding( \&settingsDialog,        "\cS");
$cui->set_binding( \&exitDialog,            "\cQ");
$cui->set_binding( \&getStatusDialog,       "\cU");
$cui->set_binding( \&setHeadersDialog,      "\cE");
$cui->set_binding( \&getHeadersDialog,      "\cR");
$cui->set_binding( \&readTimeDialog ,       "\cT");
$cui->set_binding( \&readDeviceIdDialog ,   "\cI");
$cui->set_binding( \&versionInfoDialog ,    "\cV");
$cui->set_binding( \&displayMessageDialog , "\cG");

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
	$cui->dialog(
		-title => "Device Settings",
		-message => "HALLO"
	);
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
