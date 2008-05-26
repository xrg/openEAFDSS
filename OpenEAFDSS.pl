#!/usr/bin/perl -w

# Copyright (C) 2008 by Hasiotis Nikos
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

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
	{ -label => ' Settings  ^S', -value => \&settingsDialog },
	{ -label => ' Exit      ^Q', -value => \&exitDialog     }
];
my($menuActions) = [
	{ -label => ' Get Status     ', -value => \&getStatusDialog      },
	{ -label => ' Set Headers    ', -value => \&setHeadersDialog     },
	{ -label => ' Get Headers    ', -value => \&getHeadersDialog     },
	{ -label => ' Read Time      ', -value => \&readTimeDialog       },
	{ -label => ' Read Device ID ', -value => \&readDeviceIdDialog   },
	{ -label => ' Version Info   ', -value => \&versionInfoDialog    },
	{ -label => ' Display Message', -value => \&displayMessageDialog },
];
my($menuUtilities) = [
	{ -label => ' Browse Files   ', -value => \&browseDialog   },
	{ -label => ' Validate Files ', -value => \&validateDialog },
	{ -label => ' Check Device   ', -value => \&checkDialog    }
];
my($menuHelp) = [
	{ -label => ' Help ', -value => \&helpDialog },
	{ -label => ' About', -value => \&aboutDialog }
];
my($menuBar) = [
	{ -label => 'File',      -submenu => $menuFile      },
	{ -label => 'Actions',   -submenu => $menuActions   },
	{ -label => 'Utilities', -submenu => $menuUtilities },
	{ -label => 'Help',      -submenu => $menuHelp      }
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
	my($FD) = new EAFDSS::SDNP(DIR => $curSignsDir, SN => $curDeviceID, IP => $curIpAddress);
	%reply = $FD->GetStatus();
	$cui->dialog(
		-title => "Device Status",
		-message => sprintf("[%s]    ", $reply{DATA})
	);
}

sub setHeadersDialog {
	my($winSetHeaders) = $cui->add(
		'winSetHeaders', 'Window',
		-width          => 84,
		-height         => 23,
		-border         => 1,
		-padtop         => 2,
		-padbottom      => 2,
		-padleft        => 2,
		-padright       => 2,
		-ipad           => 1
	);

	my($i, @lblHeader, @txtHeader, @lblFont, @txtFont);
	for ($i = 1; $i < 6; $i++) {
		$lblHeader[$i] = $winSetHeaders->add(
			"lHeader$i", "Label", -text   => "Header Line #$i: ",
			-x      => 1, -y      => $i*2,
			-height => 1, -width  => 16,
			-maxlength => 11, -textalignment => 'right',
		);
		$txtHeader[$i] = $winSetHeaders->add(
			"txtHeader$i", "TextEntry", -text   => "",
			-fg     => 'black', -bg     => 'cyan',
			-x      => 18, -y      => $i*2,
			-height => 1, -width  => 30,
			-maxlength => 11,
		);
		$txtFont[$i] = $winSetHeaders->add(
			"txtFont$i", "Listbox", 
			-values    => [1, 2, 3, 4],
			-labels    => { 1 => 'Normal Printing', 
					2 => 'Double height', 
					3 => 'Double width', 
					4 => 'Double width/height'},
			-selected   => $curDebug,
			-fg     => 'white', -bg     => 'black',
			-x      => 52, -y      => $i*2,
			-height => 1, -width  => 20,
			-maxlength => 11,
		);
	}

	my($setHeadersCancel) = sub {
		$winSetHeaders->loose_focus();
		$cui->delete('winSetHeaders');
	};

	my($setHeadersOK) = sub {
		$winSetHeaders->loose_focus();
		$cui->delete('winSetHeaders');

		my($FD) = new EAFDSS::SDNP(DIR => $curSignsDir, SN => $curDeviceID, IP => $curIpAddress);
		%reply = $FD->SetHeader();
		$cui->dialog(
			-title => "Set Headers",
			-message => sprintf("[%s]    ", $reply{DATA})
		);
	};

	my($btnBox) = $winSetHeaders->add(
		"btnBox", "Buttonbox" ,
		-y => -1,
		-buttons => [
			{ -label    => '< OK >',
			  -shortcut => 'o',
			  -value    => 1,
			  -onpress  => $setHeadersOK},
			{ -label    => '< Cancel >',
			  -shortcut => 'c',
			  -value    => 0,
			  -onpress  => $setHeadersCancel}
		],
		-buttonalignment => 'middle'
	);

	$btnBox->focus();
	$winSetHeaders->modalfocus();
}

sub getHeadersDialog {
	my($FD) = new EAFDSS::SDNP(DIR => $curSignsDir, SN => $curDeviceID, IP => $curIpAddress);
	%reply = $FD->GetHeader();
	$cui->dialog(
		-title => "Get Headers",
		-message => sprintf("[%s]    ", $reply{DATA})
	);
}

sub readTimeDialog {
	my($FD) = new EAFDSS::SDNP(DIR => $curSignsDir, SN => $curDeviceID, IP => $curIpAddress);
	%reply = $FD->ReadTime();
	$cui->dialog(
		-title => "Device Time",
		-message => sprintf("[%s]    ", $reply{DATA})
	);
}

sub readDeviceIdDialog {
	my($FD) = new EAFDSS::SDNP(DIR => $curSignsDir, SN => $curDeviceID, IP => $curIpAddress);
	%reply = $FD->ReadDeviceID();
	$cui->dialog(
		-title => "Device ID",
		-message => sprintf("[%s]    ", $reply{DATA})
	);
}

sub versionInfoDialog {
	my($FD) = new EAFDSS::SDNP(DIR => $curSignsDir, SN => $curDeviceID, IP => $curIpAddress);
	%reply = $FD->VersionInfo();
	$cui->dialog(
		-title => "Device Version",
		-message => sprintf("[%s]    ", $reply{DATA})
	);
}

sub displayMessageDialog {
	my($FD) = new EAFDSS::SDNP(DIR => $curSignsDir, SN => $curDeviceID, IP => $curIpAddress);
	%reply = $FD->DisplayMessage("Hallo mitso");
	$cui->dialog(
		-title => "Device Message",
		-message => sprintf("[%s]    ", $reply{DATA})
	);
}
