###
# This dockerfile follows the instructions at https://github.com/google/syzkaller/blob/master/docs/linux/setup_ubuntu-host_qemu-vm_x86-64-kernel.md
###


###
# Set up build dependencies
###
FROM ubuntu:20.04 as build_dependencies

ENV SYZKALLER_DIR /syzkaller
ENV GCC $SYZKALLER_DIR/gcc
ENV KERNEL $SYZKALLER_DIR/kernel
ENV IMAGE $SYZKALLER_DIR/image

RUN mkdir $SYZKALLER_DIR
RUN mkdir $GCC
RUN mkdir $KERNEL
RUN mkdir $IMAGE

ENV DEBIAN_FRONTEND noninteractive

# Install additional packages
RUN apt update && apt install -y \
                    git \
                    build-essential \
                    libncurses-dev \
                    flex \
                    bison \
                    openssl \
                    libssl-dev \
                    dkms \
                    libelf-dev \
                    libudev-dev \
                    libpci-dev \
                    libiberty-dev \
                    autoconf \
                    wget \
                    qemu-kvm \
                    qemu-system-x86 \
                    bridge-utils \
                    gcc-9 g++-9 \
                    cmake

###
# Set up compilers
###
FROM build_dependencies as compiler_setup
#TODO - allow other compilers to be downloaded and built if necessary
# Get a supported version of gcc: https://github.com/google/syzkaller/blob/master/docs/syzbot.md#crash-does-not-reproduce

WORKDIR $SYZKALLER_DIR
RUN wget https://storage.googleapis.com/syzkaller/gcc-9.0.0-20181231.tar.gz
RUN tar xzvf gcc-9.0.0-20181231.tar.gz


RUN apt install -y clang

# Uncomment the following blocks to build clang from source, using same commit as syzbot

# RUN mkdir llvm-project
# WORKDIR $SYZKALLER_DIR/llvm-project
# RUN git init && git remote add origin https://github.com/llvm/llvm-project.git
# RUN git fetch --depth=1 origin c2443155a0fb245c8f17f2c1c72b6ea391e86e81 && git checkout FETCH_HEAD
# RUN mkdir build

# WORKDIR $SYZKALLER_DIR/llvm-project/build
# RUN cmake -G "Unix Makefiles" \
#             -DLLVM_ENABLE_PROJECTS='clang' \
#             -DCMAKE_BUILD_TYPE=Release \
#             -DCMAKE_INSTALL_PREFIX=/tmp/clang_install \
#              ../llvm
# RUN cmake --build . -- -j8
# RUN cmake --build . --target install


###
# Get the qemu image setup
###
FROM build_dependencies as container_setup
WORKDIR $SYZKALLER_DIR

# copy in clang binaries from previous stages
#COPY --from=compiler_setup /tmp/clang_install /usr/local

# additional utilities
RUN apt update && apt install -y iproute2 \
                                 net-tools \
                                 vim \
                                 tmux \
                                 python3 python3-pip

# Enable deb-srcs
RUN sed -i '/^#\sdeb-src /s/^#//' "/etc/apt/sources.list"

# install kernel build dependencies
RUN apt update && apt-get build-dep -y linux

# get the kernel sources
# RUN git clone https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git $KERNEL

# using image from syzkaller project
COPY ./bootstrap_img/stretch.img $IMAGE
COPY ./bootstrap_img/stretch.id_rsa $IMAGE

# copy scripts and give them execute privs
WORKDIR $SYZKALLER_DIR/bin
COPY bin/* ./
RUN chmod +x *

# disable the ssh key checking
RUN echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config


WORKDIR $SYZKALLER_DIR
ENV CRASHERS $SYZKALLER_DIR/crashers
RUN mkdir meta && mkdir crashers
COPY crashers/build_crashers.sh crashers/
RUN chmod +x crashers/build_crashers.sh

# setup scrapy scraper
RUN pip3 install scrapy
RUN pip3 install --upgrade attrs
COPY syzbot_scraper .
COPY scrape_syzbot.py .

COPY run_repro.sh .
RUN chmod +x run_repro.sh

# configure some environment variables
ENV PATH=$PATH:/syzkaller/bin

###
# Boot qemu image
###
FROM container_setup as run
CMD ["bash"]
