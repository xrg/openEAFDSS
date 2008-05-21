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
	{ -label => 'Set Headers       ^H', -value => \&setHeadersDialog  },
	{ -label => 'Get Headers       ^E', -value => \&getHeadersDialog  },
	{ -label => 'Read Time         ^T', -value => \&readTimeDialog  },
	{ -label => 'Read Device ID    ^I', -value => \&readDeviceIdDialog  },
	{ -label => 'Version Info      ^V', -value => \&versionInfoDialog  },
	{ -label => 'Display Message   ^M', -value => \&displayMessageDialog  },
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


$cui->set_binding(sub {$menu->focus()},   "\cX");
$cui->set_binding( \&settingsDialog,      "\cS");
$cui->set_binding( \&exitDialog,          "\cQ");
$cui->set_binding( \&getHeadersDialog,    "\cH");
$cui->set_binding( \&setHeadersDialog,    "\cE");
$cui->set_binding( \&readTimeDialog ,     "\cT");
$cui->set_binding( \&readDeviceIdDialog , "\cI");
$cui->set_binding( \&versionInfoDialog ,  "\cV");
$cui->set_binding( \&displayImageDialog , "\cM");

$cui->mainloop();

sub exitDialog {
	my($return) = $cui->dialog(
			-message   => "Do you really want to quit?",
			-title     => "[ Are you sure? ]", 
			-buttons   => ['yes', 'no'],
			-fg        => 'gray',
			-bg        => 'blue',
			-tfg       => 'black',
			-tbg       => 'white',
			-bfg       => 'red',
			-bbg       => 'red',
			-sfg       => 'red',
			-sfg       => 'red',
		);
	exit(0) if $return;
}

sub getStatusDialog {
	#my($FD) = new EAFDSS::SDNP(DIR => "/tmp/SIGNS", SN => "ABC02000001", IP => "miles");
	#%reply = $FD->GetStatus();
	#$cui->dialog("Raw Status: " . $reply{DATA});
	$cui->dialog("Raw Status: ");
}

