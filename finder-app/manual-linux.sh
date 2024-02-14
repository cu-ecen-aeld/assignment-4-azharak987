#!/bin/bash
# Script to build a barebones Linux kernel and root filesystem for ARM64 and boot using QEMU.

set -e
set -u

# Define variables
OUTDIR="${1:-/tmp/aeld}"
KERNEL_REPO="git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git"
KERNEL_VERSION="v5.1.10"
BUSYBOX_VERSION="1_33_1"
FINDER_APP_DIR=$(realpath "$(dirname "$0")")
ARCH="arm64"
CROSS_COMPILE="aarch64-none-linux-gnu-"

# Ensure OUTDIR is an absolute path
OUTDIR="$(realpath "$OUTDIR")"

# Create the output directory
if [ ! -d "$OUTDIR" ]; then
    echo "Creating directory $OUTDIR"
    mkdir -p "$OUTDIR" || { echo "Failed to create directory $OUTDIR"; exit 1; }
fi

# Build the Linux kernel
cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    echo "Cloning Linux Kernel repository to ${OUTDIR}/linux-stable"
    git clone "$KERNEL_REPO" --depth 1 --single-branch --branch "$KERNEL_VERSION" "${OUTDIR}/linux-stable"
fi

if [ ! -e "${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image" ]; then
    cd "${OUTDIR}/linux-stable"
    echo "Checking out kernel version $KERNEL_VERSION"
    git checkout "$KERNEL_VERSION"
    
    # Build the kernel
    make ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" defconfig
    make ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" -j$(nproc)
fi

# Create necessary base directories for the root filesystem
mkdir -p "${OUTDIR}/rootfs/{bin,dev,etc,home,lib,lib64,mnt,proc,sys,tmp,usr,var}"

# Build Busybox
cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]; then
    git clone git://busybox.net/busybox.git "${OUTDIR}/busybox"
    cd "${OUTDIR}/busybox"
    git checkout "$BUSYBOX_VERSION"
    
    # Configure and build Busybox
    make ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" defconfig
    make ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" menuconfig  # Configure Busybox options interactively
    make ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" -j$(nproc)
    make ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" install
fi

# Add library dependencies to rootfs (You need to identify and copy them)

# Create essential device nodes
mknod -m 600 "${OUTDIR}/rootfs/dev/console" c 5 1

# Clean and build the writer utility (if applicable)

# Copy Finder scripts and executables to /home directory
# cp -r "${FINDER_APP_DIR}"/* "${OUTDIR}/rootfs/home/"

# Set ownership of the root directory
chown -R root:root "${OUTDIR}/rootfs"

# Create initramfs.cpio.gz
cd "${OUTDIR}/rootfs"
find . | cpio -H newc -o > "${OUTDIR}/initramfs.cpio"
gzip -9 "${OUTDIR}/initramfs.cpio"

echo "Build completed. Output files are located in $OUTDIR"
