#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-
NUM_CPU=$(/usr/bin/nproc)


if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
    make -j ${NUM_CPU} ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs
fi

echo "Adding the Image in outdir"

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
    mkdir -p ${OUTDIR}/rootfs/bin ${OUTDIR}/rootfs/dev ${OUTDIR}/rootfs/etc ${OUTDIR}/rootfs/lib \
	     ${OUTDIR}/rootfs/proc ${OUTDIR}/rootfs/sbin ${OUTDIR}/rootfs/sys ${OUTDIR}/rootfs/tmp \
             ${OUTDIR}/rootfs/usr ${OUTDIR}/rootfs/usr/bin ${OUTDIR}/rootfs/usr/lib ${OUTDIR}/rootfs/usr/sbin \
             ${OUTDIR}/rootfs/var ${OUTDIR}/rootfs/lib64 ${OUTDIR}/rootfs/home

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} distclean 
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig


else
    cd busybox
fi

# TODO: Make and install busybox

make -j ${NUM_CPU} ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
#echo "Debug: compiled busybox"
make -j ${NUM_CPU} CONFIG_PREFIX=${OUTDIR}/rootfs ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install
#echo "Debug: installed busybox"

#echo "Debug: interpreter dependencies"
${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "program interpreter"
#echo "Debug: shared library dependencies"
${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs
SYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)
#echo "SYSROOT: ${SYSROOT}"

INTERPRETER=$(find ${SYSROOT} -name "ld-linux-aarch64.so.1")
cp $INTERPRETER $OUTDIR/rootfs/lib
cp $INTERPRETER $OUTDIR/rootfs/lib64

SHARED_LIBM=$(find ${SYSROOT} -name "libm.so.6") 
#echo "SHARED_LIBM: $SHARED_LIBM"
SHARED_LIBRESOLV=$(find ${SYSROOT} -name "libresolv.so.2")
SHARED_LIBC=$(find ${SYSROOT} -name "libc.so.6")

LIBS=($SHARED_LIBM $SHARED_LIBRESOLV $SHARED_LIBC)

for LIB in ${LIBS[@]} 
do
    cp $LIB $OUTDIR/rootfs/lib
    cp $LIB $OUTDIR/rootfs/lib64
done

chmod a+rw -R $OUTDIR/rootfs/lib
chmod a+rw -R $OUTDIR/rootfs/lib64

# TODO: Make device nodes
sudo mknod -m 666 $OUTDIR/rootfs/dev/null c 1 3
sudo mknod -m 600 $OUTDIR/rootfs/dev/console c 5 1

# TODO: Clean and build the writer utility
cd $FINDER_APP_DIR
make clean 
make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE writer


# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
cp -rH *.sh writer conf $OUTDIR/rootfs/home


# TODO: Chown the root directory
sudo chown -R root:root $OUTDIR/rootfs


# TODO: Create initramfs.cpio.gz
cd $OUTDIR/rootfs
find . | cpio -H newc -ov --owner root:root > $OUTDIR/initramfs.cpio
echo "cpio finished"

cd $OUTDIR
ls
gzip -f initramfs.cpio
echo "Copy kernel image"
cp $OUTDIR/linux-stable/arch/arm64/boot/Image $OUTDIR

echo "END"


