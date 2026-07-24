FROM centos:7

RUN set -eux; \
    sed -ri 's!^mirrorlist=!#mirrorlist=!; s!^#baseurl=http://mirror.centos.org/centos/\$releasever!baseurl=https://vault.centos.org/7.9.2009!' /etc/yum.repos.d/CentOS-Base.repo; \
    yum -y install \
      binutils \
      glibc-devel \
      libstdc++-devel; \
    locale -a | grep -qi '^en_US\.utf8$'; \
    for package in gcc gcc-c++; do \
      ! rpm -q "$package"; \
    done; \
    yum clean all; \
    rm -rf /var/cache/yum

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

ENTRYPOINT ["/bin/bash"]
