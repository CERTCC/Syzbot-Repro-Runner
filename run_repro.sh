#!/bin/bash

print_message(){
    echo ""
    echo $1
    echo ""
}

export BUG_ID="$1"


print_message "Retrieving repro files"

# get the repro files
./scrape_syzbot.py "$BUG_ID"

# build the kernel
export KERNEL_VERSION=$(cat meta/$BUG_ID.kernel_commit)

print_message "Configuring kernel commit: $KERNEL_VERSION"

cd $KERNEL
git init
git remote add origin https://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git
REF=`git ls-remote | grep $KERNEL_VERSION | cut -d '/' -f 3 | cut -d '^' -f 1`
git fetch --depth=1 origin $REF
git checkout FETCH_HEAD

cp ../meta/$BUG_ID.config .config

# this block used to figure out which compiler was used
# however syzbot has been updated and this block is broken

# if [ ! -z "$(sed "7q;d" .config | grep gcc)" ]
# then
#     print_message "Building the kernel with GCC"
#     sleep 1;
#     CC="$GCC/bin/gcc" make -j8
# elif [ ! -z "$(sed "7q;d" .config | grep clang)" ]
# then
#     print_message "Building the kernel with CLANG"
#     sleep 1;
#     CC="clang" make -j8
# fi

# so just use the default gcc installation
make -j8

#build the crashers
print_message "Building the crash test cases"
cd ../crashers
./build_crashers.sh

#run the test VM
print_message "A tmux session will start now..."
sleep 3
cd $SYZKALLER_DIR
BUG_ID=$BUG_ID ./bin/startup.sh



# docker build --build-arg KERNEL_VERSION="$(cat meta/$BUG_ID.kernel_commit)" \
#              --build-arg BUG_ID=$BUG_ID \
#              -t syzbot_repro .

# if [ $? -eq 0 ]
# then
#     docker rm syzbot_repro
#     docker run --privileged -it --name syzbot_repro syzbot_repro
# fi
