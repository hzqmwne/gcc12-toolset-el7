%global toolset_root /opt/gcc12-toolset/root
%global toolset_prefix %{toolset_root}/usr
%global debug_package %{nil}

Name:           gcc12-toolset-make
Version:        4.3
Release:        1%{?dist}
Summary:        GNU Make for gcc12-toolset
License:        GPLv3+
URL:            https://www.gnu.org/software/make/
Source0:        make-%{version}.tar.gz
BuildRequires:  gcc, make
Requires:       gcc12-toolset-runtime

%description
GNU Make 4.3 installed below %{toolset_prefix}. It is activated by the normal
gcc12-toolset SCL environment and does not replace the CentOS 7 system make.

%prep
%setup -q -n make-%{version}

%build
./configure --prefix=%{toolset_prefix} --disable-nls
make %{?_smp_mflags}

%install
make DESTDIR=%{buildroot} install
find %{buildroot}%{toolset_prefix} -name '*.la' -delete
rm -f %{buildroot}%{toolset_prefix}/share/info/dir

%check
test -x %{buildroot}%{toolset_prefix}/bin/make
%{buildroot}%{toolset_prefix}/bin/make --version | head -n1 | grep -F 'GNU Make 4.3'

%files
%{toolset_prefix}/bin/make
%{toolset_prefix}/include/gnumake.h
%{toolset_prefix}/share/info/make.info*
%{toolset_prefix}/share/man/man1/make.1*

%changelog
* Sat Jul 25 2026 Toolset Builder <builder@localhost> - 4.3-1
- Add GNU Make 4.3 as a DTS-style toolset component
