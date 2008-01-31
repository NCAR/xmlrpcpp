#!/bin/sh

# Build debian package

source ../../../repo/scripts/repo_funcs.sh

# Get the user's %_topdir
topdir=`get_rpm_topdir`

# Root of EOL repo, above fedora, epel, etc
rroot=`get_eol_repo_root`

pkg=xmlrpc++-cross
dpkg=libxmlrpc++
version=0.7
fversion=`echo $version | sed 's/\./_/g'`

set -x
shopt -s nullglob

tmpdir=/tmp/${0##*/}_$$
trap "{ rm -rf $tmpdir; exit 0; }" EXIT

# Create debian packages from RPMs
drepo=${rroot%/*}/ael-dpkgs
[ -d $rroot ] && { [ -d $drepo ] || mkdir -p $drepo; }
pdir=$tmpdir/$dpkg
[ -d $pdir ] || mkdir -p $pdir

for arch in arm armbe; do

    rpm=$topdir/RPMS/i386/${pkg}-${arch}-linux-${version}*.i386.rpm
    [ -z $rpm ] && rpm=$rroot/ael/i386/${pkg}-${arch}-linux-${version}*.i386.rpm
    [ -z $rpm ] && continue

    rpm2cpio $rpm | ( cd $pdir; cpio -idv )
    mkdir -p $pdir/usr/lib
    rsync $pdir/opt/arcom/${arch}-linux/lib/libxmlrpc++.so.0.7 $pdir/usr/lib
    rm -rf $pdir/opt

    # must sed the DEBIAN/control file to change architecture
    rsync --exclude=.svn -a DEBIAN $pdir
    sed -e "s/^Architecture:.*/Architecture: $arch/" DEBIAN/control > $pdir/DEBIAN/control

    fakeroot dpkg -b $pdir
    dpkg-name $tmpdir/${dpkg}.deb
    [ -d $drepo ] && mv $tmpdir/${dpkg}_*_${arch}.deb $drepo
    rm -rf $pdir/*
done

if [ -d $rroot ]; then
    arch=i386
    rpms=($topdir/RPMS/$arch/${pkg}-*-${version}*.$arch.rpm \
        $topdir/SRPMS/${pkg}-${version}*.src.rpm)
    copy_ael_rpms_to_eol_repo ${rpms[*]}
fi

