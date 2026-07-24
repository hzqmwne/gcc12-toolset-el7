%global toolset_root /opt/gcc12-toolset/root
%global toolset_prefix %{toolset_root}/usr
%global binutils_libdir %{toolset_prefix}/lib64/binutils
%global debug_package %{nil}
%global __provides_exclude_from ^%{toolset_root}/.*$
%global __requires_exclude ^lib(bfd|opcodes|ctf|ctf-nobfd)(-[0-9.]+)?\\.so

Name:           gcc12-toolset-binutils
Version:        2.36.1
Release:        4%{?dist}
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
# Keep the shared binutils runtime separate from the full GCC runtime. Both
# profiles expose this directory without making the private libstdc++ visible
# to the compatibility profile.
../configure \
  --prefix=%{toolset_prefix} \
  --libdir=%{binutils_libdir} \
  --build=%{_target_platform} \
  --host=%{_target_platform} \
  --target=%{_target_platform} \
  --enable-shared \
  --enable-ld \
  --enable-gold \
  --enable-lto \
  --enable-plugins \
  --enable-threads=yes \
  --enable-relro=yes \
  --enable-deterministic-archives \
  --enable-compressed-debug-sections=none \
  --enable-generate-build-notes=no \
  --disable-werror \
  --disable-nls \
  --with-sysroot=/ \
  --with-system-zlib
make %{?_smp_mflags}

%install
cd build
make DESTDIR=%{buildroot} install
find %{buildroot}%{toolset_prefix} -name '*.la' -delete
rm -f %{buildroot}%{toolset_prefix}/share/info/dir

%check
test -r %{buildroot}%{binutils_libdir}/libbfd-%{version}.so
LD_LIBRARY_PATH=%{buildroot}%{binutils_libdir} \
  %{buildroot}%{toolset_prefix}/bin/ld --version | grep '2.36.1'
LD_LIBRARY_PATH=%{buildroot}%{binutils_libdir} \
  %{buildroot}%{toolset_prefix}/bin/ld.gold --version | grep '2.36.1'

%files
%{toolset_prefix}/bin/*
%{toolset_prefix}/%{_target_platform}
%{binutils_libdir}
%{toolset_prefix}/include/*
%{toolset_prefix}/share/info/*
%{toolset_prefix}/share/man/man1/*

%changelog
* Fri Jul 24 2026 Toolset Builder <builder@localhost> - 2.36.1-4
- Rebuild with the privately bundled ISL toolchain release

* Fri Jul 24 2026 Toolset Builder <builder@localhost> - 2.36.1-3
- Enable BFD ld, gold, LTO plugins, RELRO, and threaded linker support

* Thu Jul 23 2026 Toolset Builder <builder@localhost> - 2.36.1-1
- Build isolated binutils for the GCC 12 toolset
