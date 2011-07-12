# _revision, _release, and _version should be defined on the rpmbuild command
# line like so:
#
# --define "_version 0.9.1" --define "_release 7" \
# --define "_revision 0.9.1-19-abcdef"

Name: shirasu
Version: %{_version}
Release: %{_release}%{?dist}
License: New BSD License
Group: Development/Libraries
Source: http://code.google.com/p/shirasu/downloads/list/%{name}-%{_revision}.tar.gz
Source1: shirasu_init
URL: http://www.shirasu.ws
Vendor: MiCHiLU Labs.
Packager: MiCHiLU Labs. <shirasu-user@michilu.com>
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
Summary: Shirasu WebSocket Server
Requires: PyYAML
Requires: erlang-misultin
Requires: erlang-mochiweb
Requires: erlang-sasl

%description Shirasu is a WebSocket server.

%define erlang_lib %{_libdir}/erlang
%define shirasu_lib /lib/%{name}-%{_revision}
%define init_script %{_sysconfdir}/init.d/%{name}

%define __prelink_undo_cmd /bin/cat prelink library

%prep
%setup -q -n %{name}-%{_revision}
cat > rel/vars.config <<EOF
% app.config
{web_ip,       "127.0.0.1"}.
{web_port,     8098}.
{handoff_port, 8099}.
{pb_ip,        "127.0.0.1"}.
{pb_port,      8087}.
{sasl_error_log, "%{_localstatedir}/log/%{name}/sasl-error.log"}.
{sasl_log_dir, "%{_localstatedir}/log/%{name}/sasl"}.
{map_js_vms,   8}.
{reduce_js_vms, 6}.
{hook_js_vms, 2}.
% Platform-specific installation paths
{platform_bin_dir, "%{_sbindir}"}.
{platform_data_dir, "%{_localstatedir}/lib/%{name}"}.
{platform_etc_dir, "%{_sysconfdir}/%{name}"}.
{platform_lib_dir, "%{shirasu_lib}"}.
{platform_log_dir, "%{_localstatedir}/log/%{name}"}.
% vm.args
{node,         "shirasu@127.0.0.1"}.
% bin/shirasu*
{runner_script_dir,  "%{_sbindir}"}.
{runner_base_dir,    "%{erlang_lib}"}.
{runner_etc_dir,     "%{_sysconfdir}/%{name}"}.
{runner_log_dir,     "%{_localstatedir}/log/%{name}"}.
{pipe_dir,           "%{_localstatedir}/run/%{name}/"}.
{runner_user,        "%{name}"}.
EOF

%build
mkdir %{name}
make rel4fedora

%install
mkdir -p %{buildroot}%{_sysconfdir}/%{name}
mkdir -p %{buildroot}%{erlang_lib}/lib/%{name}-%{_version}/bin
erts=`find $RPM_BUILD_DIR/%{name}-%{_revision}/rel/%{name}/erts-* -name bin -type d`
erts=${erts%/*}
erts=${erts##*/}
mkdir -p %{buildroot}%{erlang_lib}/${erts}/bin
#mkdir -p %{buildroot}%{_mandir}/man1
mkdir -p %{buildroot}%{_localstatedir}/lib/%{name}/sample
#mkdir -p %{buildroot}%{_localstatedir}/lib/%{name}/dets
mkdir -p %{buildroot}%{_localstatedir}/log/%{name}
mkdir -p %{buildroot}%{_localstatedir}/log/%{name}/sasl
mkdir -p %{buildroot}%{_localstatedir}/run/%{name}

#Copy all necessary lib files etc.
cp -r $RPM_BUILD_DIR/%{name}-%{_revision}/ebin \
		%{buildroot}%{erlang_lib}/lib/%{name}-%{_version}
cp -r $RPM_BUILD_DIR/%{name}-%{_revision}/rel/%{name}/releases \
		%{buildroot}%{erlang_lib}/lib/%{name}-%{_version}
#cp -r $RPM_BUILD_DIR/%{name}-%{_revision}/doc/man/man1/*.gz \
#		%{buildroot}%{_mandir}/man1
cp -r $RPM_BUILD_DIR/%{name}-%{_revision}/rel/files/sample/www \
		%{buildroot}%{_localstatedir}/lib/%{name}/sample
install -p -D -m 0644 \
	$RPM_BUILD_DIR/%{name}-%{_revision}/rel/%{name}/etc/app.config \
	%{buildroot}%{_sysconfdir}/%{name}/
install -p -D -m 0644 \
	$RPM_BUILD_DIR/%{name}-%{_revision}/rel/%{name}/etc/vm.args \
	%{buildroot}%{_sysconfdir}/%{name}/
install -p -D -m 0644 \
	$RPM_BUILD_DIR/%{name}-%{_revision}/rel/%{name}/etc/shirasu.yaml \
	%{buildroot}%{_sysconfdir}/%{name}/
install -p -D -m 0755 \
	$RPM_BUILD_DIR/%{name}-%{_revision}/rel/%{name}/bin/%{name} \
	%{buildroot}/%{_sbindir}/%{name}
install -p -D -m 0755 \
	$RPM_BUILD_DIR/%{name}-%{_revision}/rel/%{name}/erts-*/bin/nodetool \
	%{buildroot}%{erlang_lib}/${erts}/bin/
#install -p -D -m 0755 \
#	$RPM_BUILD_DIR/%{name}-%{_revision}/rel/%{name}/bin/%{name}-admin \
#	%{buildroot}/%{_sbindir}/%{name}-admin
install -p -D -m 0755 %{SOURCE1} %{buildroot}/%{init_script}

# Needed to work around check-rpaths which seems to be hardcoded into recent
# RPM releases
export QA_RPATHS=3


%pre
# create shirasu group only if it doesn't already exist
if ! getent group shirasu >/dev/null 2>&1; then
        groupadd -r shirasu
fi

# create shirasu user only if it doesn't already exist
if ! getent passwd shirasu >/dev/null 2>&1; then
        useradd -r -g shirasu --home %{_localstatedir}/lib/%{name} shirasu
        usermod -c "Shirasu Server" shirasu
fi

%post
# Fixup perms for SELinux
find %{erlang_lib}/lib/%{name}-%{_version} -name "*.so" -exec chcon -t textrel_shlib_t {} \;

%files
%defattr(-,shirasu,shirasu)
%attr(-,root,root) %{_libdir}/*
%dir %{_sysconfdir}/%{name}
%config(noreplace) %{_sysconfdir}/%{name}/*
%attr(0755,root,root) %{init_script}
%attr(0755,root,root) %{_sbindir}/%{name}
#%attr(0755,root,root) %{_sbindir}/%{name}-admin
#%attr(0644,root,root) %{_mandir}/man1/*
%{_localstatedir}/lib/%{name}
%{_localstatedir}/log/%{name}
%{_localstatedir}/run/%{name}

%clean
rm -rf %{buildroot}

%changelog
* Tue Jul 12 2011 ENDOH takanao <djmchl@gmail.com> 0.1.2
- fixed list of RPM requires

* Tue Jul 12 2011 ENDOH takanao <djmchl@gmail.com> 0.1.1
- included sample files

* Thu Jul 7 2011 ENDOH takanao <djmchl@gmail.com> 0.1
- first 0.1 build
