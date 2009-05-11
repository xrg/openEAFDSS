%define git_repo openeafdss
%define git_head HEAD

%define name openeafdss
%define version %git_get_ver
%define release %mkrel %git_get_rel
# define libndir %{_prefix}/lib

Name:		%{name}
Version:	%{version}
Release:	%{release}
Summary:	Greek Electronic Fiscal Signature Devices Library
Group:		System/Servers
License:	LGPL
Source0:	%{name}-%{version}.tar.gz
Vendor:        Hasiotis Nikos
BuildPrereq:	perl
BuildArch:	noarch
URL:		http://www.openeafdss.gr/
BuildRequires: perl-Test-Pod, perl-Test-Pod-Coverage

Requires: perl(Carp)  >= 1.04
Requires: perl(Class::Base) >= 0.03
Requires: perl(Config::IniFiles) >= 2.38
Requires: perl(Digest::SHA1) >= 2.11
Requires: perl(IO::Socket::INET) >= 1.31
Requires: perl(Socket) >= 1.78
Requires: perl(Switch) >= 2.10

Provides:	greek-eafdss
#Requires: udev

%description
EAFDSS - Electronic Fiscal Signature Devices Library

This library handles the communication with an Electronic Signature
Device (EAFDSS). It also handles all necessary file housekeeping
requirements by Law.


%prep
%git_get_source
%setup -q

%build
cd EAFDSS
%{__perl} Makefile.PL
%make

%install
[ -n "%{buildroot}" -a "%{buildroot}" != / ] && rm -rf %{buildroot}
cd EAFDSS
%make DESTDIR=%{buildroot} install
mv %{buildroot}/usr/local/share %{buildroot}/usr/
install -d %{buildroot}%{_var}/spool/openeafdss/infiles
install -d %{buildroot}%{_var}/spool/openeafdss/signs01
install -d %{buildroot}%{_var}/spool/openeafdss/signs02

install -d %{buildroot}/%{_sysconfdir}/openeafdss
install -d %{buildroot}%{_prefix}/libexec/

cat '-' <<EOF >%{buildroot}/%{_sysconfdir}/openeafdss/eafdss.conf
<LAN>
  Driver EAFDSS::SDNP
  Parameters 1.2.3.4
  SN ABC02000001
  DIR %{_var}/spool/openeafdss/signs01
</LAN>

<SERIAL>
  Driver EAFDSS::SDSP
  Parameters /dev/ttyS0
  SN ABC02000001
  DIR %{_var}/spool/openeafdss/signs02
</SERIAL>

EOF

install examples/OpenEAFDSS.pl %{buildroot}%{_prefix}/libexec/OpenEAFDSS.pl

%clean
[ -n "%{buildroot}" -a "%{buildroot}" != / ] && rm -rf %{buildroot}

%post
# script to run after install


%files
%defattr(0644,root,sys)
%attr(0640,root,sys)	%config(noreplace)	%{_sysconfdir}/openeafdss/eafdss.conf
%perl_sitelib/EAFDSS
%perl_sitelib/EAFDSS.pm
%attr(0750,root,sys)				%{_prefix}/libexec/OpenEAFDSS.pl
%attr(0750,lp,sys)	%dir			%{_var}/spool/openeafdss
%attr(0750,lp,sys)	%dir			%{_var}/spool/openeafdss/infiles
%attr(0644,root,root)				%{_mandir}/man3/EAFDSS*

