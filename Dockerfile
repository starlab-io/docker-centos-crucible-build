FROM starlabio/centos-base:3

LABEL maintainer="Adam Schwalm <adam.schwalm@starlab.io>"

# Install yum-plugin-ovl to work around issue with a bad
# rpmdb checksum
RUN yum install -y epel-release yum-plugin-ovl

RUN yum update -y && yum install -y \
    checkpolicy gcc python3 python3-devel iasl ncurses-devel libuuid-devel glib2-devel \
    pixman-devel selinux-policy-devel yajl-devel systemd-devel \
    glibc-devel.i686 glibc-devel \
    yum clean all && \
    rm -rf /var/cache/yum/* /tmp/* /var/tmp/*

ENV PATH=/usr/local/cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    CARGO_HOME=/usr/local/cargo \
    RUSTUP_HOME=/etc/local/cargo/rustup

RUN curl https://sh.rustup.rs -sSf > rustup-install.sh && \
    umask 020 && sh ./rustup-install.sh -y --default-toolchain 1.46.0-x86_64-unknown-linux-gnu && \
    rm rustup-install.sh && \
                            \
    # Install rustfmt / cargo fmt for testing
    rustup component add rustfmt


ENV LC_ALL=en_US.utf-8
ENV LANG=en_US.utf-8