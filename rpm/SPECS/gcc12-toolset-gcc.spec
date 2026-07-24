%global toolset_root /opt/gcc12-toolset/root
%global toolset_prefix %{toolset_root}/usr
%global binutils_libdir %{toolset_prefix}/lib64/binutils
%global gcc_target x86_64-redhat-linux
%global debug_package %{nil}
%global __provides_exclude_from ^%{toolset_root}/.*$
%global __requires_exclude ^lib(asan|atomic|cc1|cc1plugin|cp1plugin|gcc_s|gomp|isl|itm|lsan|quadmath|ssp|stdc\\+\\+|tsan|ubsan)\\.so

Name:           gcc12-toolset-gcc
Version:        12.2.1
Release:        4%{?dist}
Summary:        Complete dual-ABI GCC 12 toolchain for CentOS 7
License:        GPLv3+ and GPLv3+ with exceptions and GPLv2+ with exceptions
URL:            https://gcc.gnu.org/
Source0:        gcc-12.2.1-20221121.tar.xz
Source1:        gcc12-toolset-g++-compat
Source2:        isl-0.24.tar.bz2
Patch0:         gcc12-libstdc++-compat.patch
BuildRequires:  gcc, gcc-c++, make
BuildRequires:  gmp-devel, mpfr-devel, libmpc-devel, zlib-devel
BuildRequires:  flex, bison, texinfo, gettext, binutils
BuildRequires:  /usr/bin/python
BuildRequires:  /lib/libc.so.6 /usr/lib/libc.so
BuildRequires:  /lib64/libc.so.6 /usr/lib64/libc.so
BuildRequires:  gcc12-toolset-runtime, gcc12-toolset-binutils
Requires:       gcc12-toolset-runtime
Requires:       gcc12-toolset-binutils
Requires:       gcc12-toolset-libgcc%{?_isa} = %{version}-%{release}
Requires:       gcc12-toolset-libstdc++%{?_isa} = %{version}-%{release}
Requires:       /usr/lib/libc.so /usr/lib64/libc.so
Requires:       make

%description
A private GCC 12 compiler built on CentOS 7/glibc 2.17. Unlike the official
RHEL 7 Developer Toolset compatibility layout, this package installs a full
GCC 12 libstdc++ with dual ABI support below %{toolset_prefix}. The compiler
supports native x86_64 and -m32 C/C++, LTO, OpenMP, Graphite optimizations,
GNU plugins, and the standard GCC sanitizer runtimes.

%package -n gcc12-toolset-gcc-c++
Summary:        C++ compiler for gcc12-toolset
Requires:       gcc12-toolset-gcc%{?_isa} = %{version}-%{release}
Requires:       gcc12-toolset-libstdc++-devel%{?_isa} = %{version}-%{release}

%description -n gcc12-toolset-gcc-c++
The GCC 12 C++ compiler and cc1plus frontend.

%package -n gcc12-toolset-libgcc
Summary:        Private GCC 12 low-level runtime
Requires:       gcc12-toolset-runtime

%description -n gcc12-toolset-libgcc
The private GCC 12 libgcc_s runtime. It is not registered as a replacement for
the CentOS system libgcc_s.

%package -n gcc12-toolset-libstdc++
Summary:        Complete private GCC 12 C++ runtime
Requires:       gcc12-toolset-runtime
Requires:       gcc12-toolset-libgcc%{?_isa} = %{version}-%{release}

%description -n gcc12-toolset-libstdc++
The complete GCC 12 libstdc++.so.6 runtime with GLIBCXX symbols through
GLIBCXX_3.4.30 and both old and C++11 ABIs.

%package -n gcc12-toolset-libstdc++-devel
Summary:        Headers and linker files for the private GCC 12 C++ runtime
Requires:       gcc12-toolset-libstdc++%{?_isa} = %{version}-%{release}

%description -n gcc12-toolset-libstdc++-devel
C++ headers and development linker files for gcc12-toolset.

%package -n gcc12-toolset-libstdc++-static
Summary:        Static GCC 12 C++ runtime archives
Requires:       gcc12-toolset-libstdc++-devel%{?_isa} = %{version}-%{release}

%description -n gcc12-toolset-libstdc++-static
Static libstdc++ and libsupc++ archives, intended for producing CentOS 7
binaries with -static-libstdc++ without statically linking glibc.

%package -n gcc12-toolset-libstdc++-compat
Summary:        DTS-style CentOS 7 system libstdc++ compatibility profile
Requires:       gcc12-toolset-gcc-c++%{?_isa} = %{version}-%{release}
Requires:       libstdc++%{?_isa} >= 4.8.5
Requires:       /usr/lib/libstdc++.so.6 /usr/lib64/libstdc++.so.6

%description -n gcc12-toolset-libstdc++-compat
A second C++ development view using headers built with the archived Red Hat
Developer Toolset 12 compatibility patch, dual ABI disabled, the CentOS 7
system libstdc++.so.6 and libstdc++_nonshared.a. The GCC and binutils binaries
are shared with the full profile.

%prep
%setup -q -n gcc-12.2.1-20221121 -a 2
cd ..
rm -rf gcc-12.2.1-20221121-compat
cp -a gcc-12.2.1-20221121 gcc-12.2.1-20221121-compat
cd gcc-12.2.1-20221121-compat
%patch0 -p0
./contrib/gcc_update --touch
cd ../gcc-12.2.1-20221121

%build
export PATH=%{toolset_prefix}/bin:/usr/bin:/bin
unset LD_LIBRARY_PATH LIBRARY_PATH CPATH C_INCLUDE_PATH CPLUS_INCLUDE_PATH
export LD_LIBRARY_PATH=%{binutils_libdir}
mkdir obj
cd obj
mkdir isl-build isl-install
cd isl-build
../../isl-0.24/configure \
  CC=/usr/bin/gcc \
  CXX=/usr/bin/g++ \
  CFLAGS='%{optflags} -fpic' \
  --prefix="$(cd .. && pwd)/isl-install" \
  --enable-shared \
  --disable-static
make %{?_smp_mflags}
make install
cd ..

../configure \
  --prefix=%{toolset_prefix} \
  --libdir=%{toolset_prefix}/lib64 \
  --with-local-prefix=%{toolset_prefix} \
  --with-gxx-include-dir=%{toolset_prefix}/include/c++/%{version} \
  --build=%{gcc_target} \
  --host=%{gcc_target} \
  --target=%{gcc_target} \
  --enable-bootstrap \
  --enable-languages=c,c++,lto \
  --enable-shared \
  --enable-threads=posix \
  --enable-checking=release \
  --enable-__cxa_atexit \
  --enable-gnu-unique-object \
  --enable-linker-build-id \
  --with-linker-hash-style=gnu \
  --enable-plugin \
  --enable-initfini-array \
  --enable-gnu-indirect-function \
  --enable-libstdcxx-dual-abi \
  --enable-libstdcxx-backtrace \
  --with-default-libstdcxx-abi=new \
  --with-system-zlib \
  --with-isl="$(pwd)/isl-install" \
  --with-arch_32=x86-64 \
  --with-arch_64=x86-64 \
  --with-tune=generic \
  --with-boot-ldflags='-static-libstdc++ -static-libgcc' \
  --enable-multilib \
  --enable-libsanitizer \
  --disable-libunwind-exceptions \
  --disable-nls
make %{?_smp_mflags} \
  LDFLAGS_FOR_TARGET='-Wl,-z,relro,-z,now' \
  profiledbootstrap
cp -a isl-install/lib/libisl.so.23 gcc/

# Build only the compiler and target libstdc++ a second time from the DTS
# compatibility source view. This shares the installed GCC binaries while
# producing the patched headers and RHEL 7/GCC 4.8 nonshared archive.
cd ..
mkdir obj-compat
cd obj-compat
../../gcc-12.2.1-20221121-compat/configure \
  --prefix=%{toolset_prefix} \
  --libdir=%{toolset_prefix}/lib64 \
  --with-local-prefix=%{toolset_prefix} \
  --with-gxx-include-dir=%{toolset_prefix}/include/c++/%{version} \
  --build=%{gcc_target} \
  --host=%{gcc_target} \
  --target=%{gcc_target} \
  --disable-bootstrap \
  --enable-languages=c,c++ \
  --enable-shared \
  --enable-threads=posix \
  --enable-checking=release \
  --enable-__cxa_atexit \
  --enable-gnu-unique-object \
  --enable-linker-build-id \
  --with-linker-hash-style=gnu \
  --enable-plugin \
  --enable-initfini-array \
  --enable-gnu-indirect-function \
  --enable-libstdcxx-dual-abi \
  --with-default-libstdcxx-abi=gcc4-compatible \
  --with-system-zlib \
  --with-isl="$(pwd)/../obj/isl-install" \
  --with-arch_32=x86-64 \
  --with-arch_64=x86-64 \
  --with-tune=generic \
  --enable-multilib \
  --disable-libsanitizer \
  --disable-libunwind-exceptions \
  --disable-nls
make %{?_smp_mflags} all-gcc all-target-libgcc all-target-libstdc++-v3

%install
export PATH=%{toolset_prefix}/bin:/usr/bin:/bin
export LD_LIBRARY_PATH=%{binutils_libdir}
cd obj
make DESTDIR=%{buildroot} install
install -m 0755 isl-install/lib/libisl.so.23 \
  %{buildroot}%{toolset_prefix}/lib/gcc/%{gcc_target}/%{version}/libisl.so.23
find %{buildroot}%{toolset_prefix} -name '*.la' -delete
rm -f %{buildroot}%{toolset_prefix}/share/info/dir

# Install the patched headers into a temporary root, then expose them as a
# separate profile. Never overwrite the full dual-ABI header tree.
compat_root=$(pwd)/compat-root
rm -rf "$compat_root"
make -C ../obj-compat DESTDIR="$compat_root" \
  install-gcc install-target-libgcc install-target-libstdc++-v3
compat_profile=%{buildroot}/opt/gcc12-toolset/profiles/compat
install -d "$compat_profile/include/c++" \
  "$compat_profile/bin" \
  "$compat_profile/lib/gcc/%{gcc_target}/%{version}/32"
cp -a "$compat_root%{toolset_prefix}/include/c++/%{version}" \
  "$compat_profile/include/c++/"

# The official RHEL 7 DTS model unconditionally disables the new ABI because
# it cannot be provided by system libstdc++.so.6 plus a nonshared archive.
find "$compat_profile/include/c++/%{version}" -name c++config.h -print0 \
  | xargs -0 sed -i \
      's/\(define[[:blank:]]*_GLIBCXX_USE_DUAL_ABI[[:blank:]]*\)1/\10/'

compat_lib="$compat_profile/lib/gcc/%{gcc_target}/%{version}"
install -m 0644 \
  ../obj-compat/%{gcc_target}/libstdc++-v3/src/.libs/libstdc++_nonshared48.a \
  "$compat_lib/libstdc++_nonshared.a"
install -m 0644 \
  ../obj-compat/%{gcc_target}/32/libstdc++-v3/src/.libs/libstdc++_nonshared48.a \
  "$compat_lib/32/libstdc++_nonshared.a"
cat > "$compat_lib/libstdc++.so" <<'EOF'
/* GNU ld script: CentOS 7 system runtime plus DTS 12 compatibility objects. */
OUTPUT_FORMAT(elf64-x86-64)
INPUT ( /usr/lib64/libstdc++.so.6 -lstdc++_nonshared )
EOF
cat > "$compat_lib/32/libstdc++.so" <<'EOF'
/* GNU ld script: CentOS 7 i686 system runtime plus DTS 12 compatibility objects. */
OUTPUT_FORMAT(elf32-i386)
INPUT ( /usr/lib/libstdc++.so.6 -lstdc++_nonshared )
EOF
install -m 0755 %{SOURCE1} "$compat_profile/bin/g++"
ln -s g++ "$compat_profile/bin/c++"
ln -s g++ "$compat_profile/bin/%{gcc_target}-g++"
ln -s g++ "$compat_profile/bin/%{gcc_target}-c++"

# Compile the GDB pretty-printers before enumerating the package manifests.
# CentOS 7's BRP script performs this after %%install, which would otherwise
# create unowned bytecode after the manifests have already been generated.
find %{buildroot}%{toolset_prefix} -type f -name '*.py' -print \
  | while IFS= read -r python_file; do
      installed_path=${python_file#%{buildroot}}
      PYTHON_FILE="$python_file" INSTALLED_PATH="$installed_path" \
        /usr/bin/python -c \
          'import os, py_compile; py_compile.compile(os.environ["PYTHON_FILE"], dfile=os.environ["INSTALLED_PATH"], doraise=True)'
      PYTHON_FILE="$python_file" INSTALLED_PATH="$installed_path" \
        /usr/bin/python -O -c \
          'import os, py_compile; py_compile.compile(os.environ["PYTHON_FILE"], dfile=os.environ["INSTALLED_PATH"], doraise=True)'
    done

# Build non-overlapping file manifests. Directory ownership belongs to runtime.
find %{buildroot}/opt/gcc12-toolset \( -type f -o -type l \) \
  | sed 's#^%{buildroot}##' | LC_ALL=C sort > files.all

grep -E '^/opt/gcc12-toolset/profiles/compat/' files.all \
  > files.compat || :
grep -v '^/opt/gcc12-toolset/profiles/compat/' files.all \
  > files.noncompat || :
grep -E '/libstdc\+\+\.so\.6([^/]*)$' files.noncompat \
  > files.libstdcxx || :
grep -E '/libgcc_s\.so([^/]*)$' files.noncompat \
  > files.libgcc || :
grep -E '/lib(stdc\+\+|supc\+\+|stdc\+\+fs|stdc\+\+_libbacktrace)\.a$' files.noncompat \
  > files.static || :
grep -E '(/include/c\+\+/|/libstdc\+\+\.so$)' files.noncompat \
  > files.devel || :
grep -E '(/bin/([^/]+-)?(g\+\+|c\+\+)$|/libexec/gcc/.*/cc1plus$|/share/man/man1/([^/]+-)?(g\+\+|c\+\+)\.1$)' files.noncompat \
  > files.cxx || :

cat files.compat files.libstdcxx files.libgcc files.static files.devel files.cxx \
  | LC_ALL=C sort -u > files.assigned
LC_ALL=C comm -23 files.all files.assigned > files.gcc

# Fail if a path was accidentally assigned to two subpackages.
assigned_count=$(cat files.compat files.libstdcxx files.libgcc files.static files.devel files.cxx | wc -l)
unique_count=$(cat files.compat files.libstdcxx files.libgcc files.static files.devel files.cxx | sort -u | wc -l)
test "$assigned_count" -eq "$unique_count"

test -s files.gcc
test -s files.cxx
test -s files.libgcc
test -s files.libstdcxx
test -s files.devel
test -s files.static
test -s files.compat

%check
export PATH=%{toolset_prefix}/bin:/usr/bin:/bin
export LD_LIBRARY_PATH=%{binutils_libdir}
test -x obj/gcc/xgcc
obj/gcc/xgcc -Bobj/gcc -dumpfullversion | grep '^12\.2\.1$'
test "$(obj/gcc/xgcc -Bobj/gcc -m32 -print-multi-directory)" = 32
config_header=$(find %{buildroot}%{toolset_prefix}/include/c++/%{version} -name c++config.h | head -n 1)
test -n "$config_header"
grep -q '^# define _GLIBCXX_USE_CXX11_ABI 1' "$config_header"
grep -q 'GLIBCXX_3.4.30' %{buildroot}%{toolset_prefix}/lib64/libstdc++.so.6.0.30
grep -q 'GLIBCXX_3.4.30' %{buildroot}%{toolset_prefix}/lib/libstdc++.so.6.0.30
test -r %{buildroot}%{toolset_prefix}/lib64/libasan.so.8
test -r %{buildroot}%{toolset_prefix}/lib/libasan.so.8
test -r %{buildroot}%{toolset_prefix}/lib64/libubsan.so.1
test -r %{buildroot}%{toolset_prefix}/lib/libubsan.so.1
find %{buildroot}%{toolset_prefix} -name libstdc++_libbacktrace.a -print -quit \
  | grep -q .
test -r %{buildroot}%{toolset_prefix}/lib/gcc/%{gcc_target}/%{version}/libisl.so.23
compat_header=$(find %{buildroot}/opt/gcc12-toolset/profiles/compat/include \
  -name c++config.h | head -n 1)
test -n "$compat_header"
grep -Eq 'define[[:blank:]]+_GLIBCXX_USE_DUAL_ABI[[:blank:]]+0' "$compat_header"
grep -q '/usr/lib64/libstdc++.so.6' \
  %{buildroot}/opt/gcc12-toolset/profiles/compat/lib/gcc/%{gcc_target}/%{version}/libstdc++.so
ar t %{buildroot}/opt/gcc12-toolset/profiles/compat/lib/gcc/%{gcc_target}/%{version}/libstdc++_nonshared.a | grep -q '\.o$'
grep -q '/usr/lib/libstdc++.so.6' \
  %{buildroot}/opt/gcc12-toolset/profiles/compat/lib/gcc/%{gcc_target}/%{version}/32/libstdc++.so
ar t %{buildroot}/opt/gcc12-toolset/profiles/compat/lib/gcc/%{gcc_target}/%{version}/32/libstdc++_nonshared.a | grep -q '\.o$'

%files -f obj/files.gcc

%files -n gcc12-toolset-gcc-c++ -f obj/files.cxx

%files -n gcc12-toolset-libgcc -f obj/files.libgcc

%files -n gcc12-toolset-libstdc++ -f obj/files.libstdcxx

%files -n gcc12-toolset-libstdc++-devel -f obj/files.devel

%files -n gcc12-toolset-libstdc++-static -f obj/files.static

%files -n gcc12-toolset-libstdc++-compat -f obj/files.compat

%changelog
* Fri Jul 24 2026 Toolset Builder <builder@localhost> - 12.2.1-4
- Build the locked GCC upstream ISL 0.24 prerequisite privately

* Fri Jul 24 2026 Toolset Builder <builder@localhost> - 12.2.1-3
- Enable x86_64 multilib and common GCC development features
- Add private sanitizer runtimes, Graphite, and libstdc++ backtrace support

* Thu Jul 23 2026 Toolset Builder <builder@localhost> - 12.2.1-1
- Build complete GCC 12 libstdc++ with dual ABI and new ABI default
- Keep all compiler and runtime files isolated below /opt/gcc12-toolset
