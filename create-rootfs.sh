#!/bin/bash

#
# Author: Badr BADRI © pythops
#

set -e

ARCH=arm64
RELEASE=bionic
MIRROR_URL=http://mirrors.ustc.edu.cn
CD_URL=http://mirrors.ustc.edu.cn/ubuntu-cdimage
PORT_URL=http://mirrors.ustc.edu.cn/ubuntu-ports
JETSON_ROOTFS_DIR=`pwd`/jetson_rootfs

# Check if the user is not root
if [ "x$(whoami)" != "xroot" ]; then
	printf "\e[31mThis script requires root privilege\e[0m\n"
	exit 1
fi

# Check for env variables
if [ ! $JETSON_ROOTFS_DIR ]; then
	printf "\e[31mYou need to set the env variable \$JETSON_ROOTFS_DIR\e[0m\n"
	exit 1
fi

# Install prerequisites packages
printf "\e[32mInstall the dependencies...  "
apt-get update > /dev/null
apt-get install --no-install-recommends -y qemu-user-static debootstrap coreutils parted wget gdisk e2fsprogs > /dev/null
printf "[OK]\n"

# Create rootfs directory
printf "Create rootfs directory...    "
mkdir -p $JETSON_ROOTFS_DIR
printf "[OK]\n"

# Download ubuntu base image
if [ ! "$(ls -A $JETSON_ROOTFS_DIR)" ]; then
	printf "Download the base image...   "
  	# wget -qO- http://cdimage.ubuntu.com/ubuntu-base/releases/18.04.3/release/ubuntu-base-18.04.3-base-arm64.tar.gz | tar xzvf - -C $JETSON_ROOTFS_DIR > /dev/null
	wget -qO- ${CD_URL}/ubuntu-base/releases/18.04.3/release/ubuntu-base-18.04.3-base-arm64.tar.gz | tar xzvf - -C $JETSON_ROOTFS_DIR > /dev/null
	printf "[OK]\n"
else
	printf "Base image already downloaded"
fi
	
# Replace the http://ports.ubuntu.com/ubuntu-ports/ with http://mirrors.ustc.edu.cn/ubuntu-ports/
sed -i 's#http://ports.ubuntu.com/ubuntu-ports/#http://mirrors.ustc.edu.cn/ubuntu-ports/#g' $JETSON_ROOTFS_DIR/etc/apt/sources.list

# Run debootsrap first stage
printf "Run debootstrap first stage...  "
debootstrap \
        --arch=$ARCH \
        --keyring=/usr/share/keyrings/ubuntu-archive-keyring.gpg \
        --foreign \
        --variant=minbase \
	--include=python3 \
        $RELEASE \
	$JETSON_ROOTFS_DIR \
	${PORT_URL} > /dev/null
printf "[OK]\n"

# Copy qemu-aarch64-static
cp /usr/bin/qemu-aarch64-static $JETSON_ROOTFS_DIR/usr/bin

# Run debootstrap second stage
printf "Run debootstrap second stage... "
chroot $JETSON_ROOTFS_DIR /bin/bash -c "/debootstrap/debootstrap --second-stage"  > /dev/null
printf "[OK]\n"

printf "Success!\n"
