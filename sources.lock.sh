# shellcheck shell=sh
# CentOS devtoolset-12 archived source snapshot.
GCC_SOURCE=gcc-12.2.1-20221121.tar.xz
GCC_URL=https://git.centos.org/sources/devtoolset-12-gcc/c7/ecaedb16188931aa35d627f2edb28dbab5f8f3c1
GCC_FALLBACK_URL=https://git.centos.org/devtoolset-12-gcc/c7/ecaedb16188931aa35d627f2edb28dbab5f8f3c1
GCC_SHA1=ecaedb16188931aa35d627f2edb28dbab5f8f3c1

# GCC upstream prerequisite used by the archived devtoolset-12 build.
ISL_SOURCE=isl-0.24.tar.bz2
ISL_URL=https://gcc.gnu.org/pub/gcc/infrastructure/isl-0.24.tar.bz2
ISL_FALLBACK_URL=https://downloads.sourceforge.net/project/libisl/isl-0.24.tar.bz2
ISL_SHA256=fcf78dd9656c10eb8cf9fbd5f59a0b6b01386205fe1934b3b287a0a1898145c0

# Companion source version used by devtoolset-12.
BINUTILS_SOURCE=binutils-2.36.1.tar.xz
BINUTILS_URL=https://ftpmirror.gnu.org/binutils/binutils-2.36.1.tar.xz
BINUTILS_FALLBACK_URL=https://ftp.gnu.org/gnu/binutils/binutils-2.36.1.tar.xz
BINUTILS_SHA1=021c97cc0e751e989afb8db025fbd2ae48391831

# Red Hat/CentOS DTS 12 compatibility model for RHEL 6/7 system libstdc++.
LIBSTDCXX_COMPAT_PATCH=gcc12-libstdc++-compat.patch
LIBSTDCXX_COMPAT_PATCH_URL=https://gitlab.com/CentOS/archives/git.centos.org/rpms/devtoolset-12-gcc/-/raw/5e6e6db9f32771a6542d4fcc5a5e898e44b9491f/SOURCES/gcc12-libstdc++-compat.patch
LIBSTDCXX_COMPAT_PATCH_FALLBACK_URL=https://gitlab.com/api/v4/projects/71903548/repository/files/SOURCES%2Fgcc12-libstdc%2B%2B-compat.patch/raw?ref=5e6e6db9f32771a6542d4fcc5a5e898e44b9491f
LIBSTDCXX_COMPAT_PATCH_SHA256=7a5b89af6fc10a00e61b374b86c49591bd7696cc2b518f3ecad6568033967aa5
