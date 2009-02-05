#!/bin/sh

# Build debian package

source repo_scripts/repo_funcs.sh

# Get the user's %_topdir
topdir=`get_rpm_topdir`

# Root of EOL repo, above fedora, epel, etc
rroot=`get_eol_repo_root`

pkg=xmlrpc++-cross
dpkg=libxmlrpc++
version=0.7
fversion=`echo $version | sed 's/\./_/g'`

# set -x
shopt -s nullglob

tmpdir=/tmp/${0##*/}_$$
trap "{ rm -rf $tmpdir; exit 0; }" EXIT

# Create debian packages from RPMs
# Where to put the debian packages.
dest=${DPKGDEST:-/opt/local/ael-dpkgs}
[ -d $dest ] || mkdir -p $dest

pdir=$tmpdir/$dpkg
[ -d $pdir ] || mkdir -p $pdir

for arch in arm armbe; do

    rpm=($topdir/RPMS/i386/${pkg}-${arch}-linux-${version}*.i386.rpm)
    [ ${#rpm[*]} -eq 0 ] && \
        rpm=($rroot/ael/i386/${pkg}-${arch}-linux-${version}*.i386.rpm)
    [ ${#rpm[*]} -eq 0 ] && continue
    # get last rpm name in case there are multiple versions
    rpm=${rpm[${#rpm[*]}-1]}            # love that syntax!

    rpm2cpio $rpm | ( cd $pdir; cpio -idv )
    mkdir -p $pdir/usr/lib
    rsync -l $pdir/opt/arcom/${arch}-linux/lib/libxmlrpc++.so* $pdir/usr/lib
    rm -rf $pdir/opt

    # must sed the DEBIAN/control file to change architecture
    rsync --exclude=.svn -a DEBIAN $pdir
    sed -e "s/^Architecture:.*/Architecture: $arch/" DEBIAN/control > $pdir/DEBIAN/control

    fakeroot dpkg -b $pdir
    dpkg-name $tmpdir/${dpkg}.deb
    deb=($tmpdir/${dpkg}_*_${arch}.deb)
    if [ ${#deb[*]} -eq 0 ]; then
        echo "error, can't find the debian package"
        exit 1
    fi
    dfile=${deb[0]}
    rsync -t $dfile $dest || continue
    dfile=$dest/${dfile##*/}
    verfile=${dfile%.deb}.ver
    cksum $dfile > $verfile
    dv=`awk '/^Version:/{print $2}' DEBIAN/control`
    sv=`svnversion .`
    echo "$dv $sv `date +%Y%m%d%H%M%S`" >> $verfile
    echo "Debian package: $dfile"
    echo "Version file: $verfile"
    cat $verfile
    rm -rf $pdir/*
done

