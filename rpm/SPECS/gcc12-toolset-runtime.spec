Name:           gcc12-toolset-runtime
Version:        1.0
Release:        5%{?dist}
Summary:        Runtime launcher and filesystem layout for gcc12-toolset
License:        MIT
BuildArch:      noarch
Source0:        gcc12-toolset
Source1:        enable
Source2:        enable-private
Source3:        enable-system
Source4:        enable-full
Source5:        enable-compat

%description
Filesystem layout and environment launchers for an isolated GCC 12 toolset.
The package does not replace the CentOS system compiler or system libstdc++.

%prep

%build

%install
install -d %{buildroot}/opt/gcc12-toolset/root/usr/{bin,lib,lib64,include,share}
install -d %{buildroot}/usr/bin
install -m 0755 %{SOURCE0} %{buildroot}/usr/bin/gcc12-toolset
ln -s gcc12-toolset %{buildroot}/usr/bin/gcc12-toolset-full
ln -s gcc12-toolset %{buildroot}/usr/bin/gcc12-toolset-compat
install -m 0644 %{SOURCE1} %{buildroot}/opt/gcc12-toolset/enable
install -m 0644 %{SOURCE2} %{buildroot}/opt/gcc12-toolset/enable-private
install -m 0644 %{SOURCE3} %{buildroot}/opt/gcc12-toolset/enable-system
install -m 0644 %{SOURCE4} %{buildroot}/opt/gcc12-toolset/enable-full
install -m 0644 %{SOURCE5} %{buildroot}/opt/gcc12-toolset/enable-compat

%files
%dir /opt/gcc12-toolset
%dir /opt/gcc12-toolset/root
%dir /opt/gcc12-toolset/root/usr
%dir /opt/gcc12-toolset/root/usr/bin
%dir /opt/gcc12-toolset/root/usr/lib
%dir /opt/gcc12-toolset/root/usr/lib64
%dir /opt/gcc12-toolset/root/usr/include
%dir /opt/gcc12-toolset/root/usr/share
/opt/gcc12-toolset/enable
/opt/gcc12-toolset/enable-private
/opt/gcc12-toolset/enable-system
/opt/gcc12-toolset/enable-full
/opt/gcc12-toolset/enable-compat
/usr/bin/gcc12-toolset
/usr/bin/gcc12-toolset-full
/usr/bin/gcc12-toolset-compat

%changelog
* Fri Jul 24 2026 Toolset Builder <builder@localhost> - 1.0-5
- Add the compiler private dependency directory to both profiles

* Fri Jul 24 2026 Toolset Builder <builder@localhost> - 1.0-4
- Rebuild with the privately bundled ISL toolchain release

* Fri Jul 24 2026 Toolset Builder <builder@localhost> - 1.0-3
- Expose isolated 64-bit and 32-bit runtime directories in the full profile

* Thu Jul 23 2026 Toolset Builder <builder@localhost> - 1.0-1
- Initial isolated runtime layout
