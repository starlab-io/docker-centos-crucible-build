FROM starlabio/centos-base:3

LABEL maintainer="Adam Schwalm <adam.schwalm@starlab.io>"

# Install yum-plugin-ovl to work around issue with a bad
# rpmdb checksum, as well as a few other things that must
# be installed prior to the general install step below
RUN yum install -y \
    # Add the EPEL for python3 and other new packages \
    epel-release \
    # Add the overlay plugin \
    yum-plugin-ovl \
    # Add endpoint for the updated git version (needed for titanium) \
    https://packages.endpoint.com/rhel/7/os/x86_64/endpoint-repo-1.7-1.x86_64.rpm \
    && yum clean all && \
    rm -rf /var/cache/yum/* /tmp/* /var/tmp/*

RUN yum update -y && yum install -y \
    \
    # Dependencies for building xen \
    checkpolicy gcc python3 python3-devel iasl ncurses-devel libuuid-devel glib2-devel \
    pixman-devel selinux-policy-devel yajl-devel systemd-devel \
    glibc-devel.i686 glibc-devel \
    \
    # Dependencies for building qemu \
    git libfdt-devel zlib-devel \
    \
    # Crucible build dependencies \
    squashfs-tools \
    \
    # Dependencies for starting build as non-root user \
    sudo \
    \
    # Dependiences for Transient shared folder support \
    openssh-server \
    \
    # Dependiences for building Titanium libfortifs \
    prelink \
    && yum clean all && \
    rm -rf /var/cache/yum/* /tmp/* /var/tmp/*

ENV PATH=/usr/local/cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    CARGO_HOME=/usr/local/cargo \
    RUSTUP_HOME=/etc/local/cargo/rustup

RUN curl https://sh.rustup.rs -sSf > rustup-install.sh && \
    umask 020 && sh ./rustup-install.sh -y --default-toolchain 1.50.0-x86_64-unknown-linux-gnu && \
    rm rustup-install.sh && \
                            \
    # Install rustfmt / cargo fmt for testing
    rustup component add rustfmt clippy

# Build and install qemu
RUN git clone --depth 1 --branch v5.1.0 git://git.qemu-project.org/qemu.git && \
    cd qemu && \
    ./configure --target-list=x86_64-softmmu && \
    make -j4 && make install

# Install python2 dependencies
RUN pip install behave==1.2.6 pyhamcrest==1.10.1

# Install python3 dependencies
RUN pip3 install transient==0.15

# Allow any user to have sudo access within the container
ARG VER=1
ARG ZIP_FILE=add-user-to-sudoers.zip
RUN wget -nv "https://github.com/starlab-io/add-user-to-sudoers/releases/download/${VER}/${ZIP_FILE}" && \
    unzip "${ZIP_FILE}" && \
    rm "${ZIP_FILE}" && \
    mkdir -p /usr/local/bin && \
    mv add_user_to_sudoers /usr/local/bin/ && \
    mv startup_script /usr/local/bin/ && \
    chmod 4755 /usr/local/bin/add_user_to_sudoers && \
    chmod +x /usr/local/bin/startup_script && \
    # Let regular users be able to use sudo
    echo $'auth       sufficient    pam_permit.so\n\
account    sufficient    pam_permit.so\n\
session    sufficient    pam_permit.so\n\
' > /etc/pam.d/sudo

ENV LC_ALL=en_US.utf-8
ENV LANG=en_US.utf-8

ENTRYPOINT ["/usr/local/bin/startup_script"]
CMD ["/bin/bash", "-l"]
