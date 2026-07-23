%global toolset_root /opt/gcc12-toolset/root
%global toolset_prefix %{toolset_root}/usr
%global debug_package %{nil}
%global __provides_exclude_from ^%{toolset_root}/.*$

Name:           gcc12-toolset-binutils
Version:        2.36.1
Release:        1%{?dist}
Summary:        Private binutils for gcc12-toolset
License:        GPLv3+
URL:            https://www.gnu.org/software/binutils/
Source0:        binutils-%{version}.tar.xz
BuildRequires:  gcc, gcc-c++, make, flex, bison, texinfo, zlib-devel
Requires:       gcc12-toolset-runtime

%description
GNU binutils installed below %{toolset_prefix}. It does not replace the
CentOS 7 system binutils.

%prep
%setup -q -n binutils-%{version}

%build
mkdir build
cd build
# The compat profile deliberately excludes the private lib64 directory from
# LD_LIBRARY_PATH. Link binutils to its internal libraries statically so tools
# such as ld remain usable in both profiles without exposing private runtimes.
../configure \
  --prefix=%{toolset_prefix} \
  --libdir=%{toolset_prefix}/lib64 \
  --build=%{_target_platform} \
  --host=%{_target_platform} \
  --target=%{_target_platform} \
  --disable-shared \
  --enable-plugins \
  --enable-threads \
  --enable-deterministic-archives \
  --disable-werror \
  --disable-nls \
  --with-system-zlib
make %{?_smp_mflags}

%install
cd build
make DESTDIR=%{buildroot} install
find %{buildroot}%{toolset_prefix} -name '*.la' -delete
rm -f %{buildroot}%{toolset_prefix}/share/info/dir

%check
%{buildroot}%{toolset_prefix}/bin/ld --version | grep '2.36.1'

%files
%{toolset_prefix}/bin/*
%{toolset_prefix}/lib/*
%{toolset_prefix}/lib64/*
%{toolset_prefix}/include/*
%{toolset_prefix}/share/info/*
%{toolset_prefix}/share/man/man1/*

%changelog
* Thu Jul 23 2026 Toolset Builder <builder@localhost> - 2.36.1-1
- Build isolated binutils for the GCC 12 toolset
