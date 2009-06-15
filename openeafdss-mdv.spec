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
pushd examples/TypeA
%make
popd

%install
[ -n "%{buildroot}" -a "%{buildroot}" != / ] && rm -rf %{buildroot}
cd EAFDSS
%make DESTDIR=%{buildroot} install

pushd examples/TypeA
%make DESTDIR=%{buildroot} install
popd

mv %{buildroot}/usr/local/share %{buildroot}/usr/
install -d %{buildroot}%{_var}/spool/openeafdss/infiles
install -d %{buildroot}%{_var}/spool/openeafdss/signs01
install -d %{buildroot}%{_var}/spool/openeafdss/signsA
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

cat '-' <<EOF >%{buildroot}/%{_sysconfdir}/openeafdss/typea.ini
[main]
sqlite=%{_var}/spool/openeafdss/typeA.sqlite
abc_dir=%{_var}/spool/openeafdss/signsA
; note that the above must be the same dir per device, for all OpenEAFDSS
; interfaces.

[device]
driver=SDNP
param=miles
sn=ABC02000001

EOF

install examples/OpenEAFDSS.pl %{buildroot}%{_prefix}/libexec/OpenEAFDSS.pl

# Type A support:
install -d %{buildroot}%{_var}/spool/openeafdss/eafdss-db
install -D examples/TypeA/OpenEAFDSS-TypeA-Filter.pl %{buildroot}/usr/lib/cups/filter/openeafdss
# Skip this, we will use the same .ini as the main prog.
# install OpenEAFDSS-TypeA.ini /etc/OpenEAFDSS/OpenEAFDSS-TypeA.ini
#
install -D examples/TypeA/OpenEAFDSS-TypeA.pl %{buildroot}%{_bindir}/OpenEAFDSS-TypeA.pl

%clean
[ -n "%{buildroot}" -a "%{buildroot}" != / ] && rm -rf %{buildroot}

%post
# script to run after install
if [ ! -f /etc/cups/local.types ] || ! (grep -q 'text/plain-eafdss' /etc/cups/local.types) ; then
	echo 'text/plain-eafdss' >> /etc/cups/local.types
fi


%files
%defattr(0644,root,sys)
%attr(0644,root,sys)	%config(noreplace)	%{_sysconfdir}/openeafdss/eafdss.conf
%attr(0644,root,sys)	%config(noreplace)	%{_sysconfdir}/openeafdss/typea.ini
%attr(0755,root,sys)				%perl_sitelib/EAFDSS
%attr(0755,root,sys)				%perl_sitelib/EAFDSS.pm
%attr(0755,root,sys)				%{_prefix}/libexec/OpenEAFDSS.pl
%attr(0750,lp,sys)	%dir			%{_var}/spool/openeafdss
%attr(0750,lp,sys)	%dir			%{_var}/spool/openeafdss/infiles
%attr(0644,root,root)				%{_mandir}/man3/EAFDSS*
%attr(0755,lp,sys)	%dir			%{_var}/spool/openeafdss/signsA
%attr(0750,root,root)				/usr/lib/cups/filter/openeafdss
%attr(0755,root,root)				%{_bindir}/OpenEAFDSS-TypeA.pl

