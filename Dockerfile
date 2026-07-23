FROM centos:7

ARG BUILD_JOBS=8
ENV BUILD_JOBS=${BUILD_JOBS} \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN set -eux; \
    sed -ri 's!^mirrorlist=!#mirrorlist=!; s!^#baseurl=http://mirror.centos.org/centos/\$releasever!baseurl=https://vault.centos.org/7.9.2009!' /etc/yum.repos.d/CentOS-Base.repo; \
    yum -y install epel-release; \
    sed -ri 's!^metalink=!#metalink=!; s!^#baseurl=https?://download.fedoraproject.org/pub/epel/7/!baseurl=https://archives.fedoraproject.org/pub/archive/epel/7/!' /etc/yum.repos.d/epel.repo; \
    yum -y install \
      rpm-build rpmdevtools redhat-rpm-config \
      gcc gcc-c++ make binutils \
      glibc-devel libstdc++-devel \
      gmp-devel mpfr-devel libmpc-devel zlib-devel \
      bison flex texinfo gettext dejagnu expect \
      perl python3 patch diffutils file findutils which \
      curl ca-certificates tar gzip bzip2 xz; \
    yum clean all; \
    rm -rf /var/cache/yum

COPY . /workspace
RUN chmod +x /workspace/*.sh /workspace/rpm/SOURCES/* /workspace/tests/*.sh

WORKDIR /workspace
ENTRYPOINT ["/workspace/docker-build.sh"]
