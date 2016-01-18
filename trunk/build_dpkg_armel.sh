#!/bin/bash

# Build source and binary debian packages of xmlrpc++

if [ $# -eq 0 ]; then
    echo "Usage: ${0##*/} destination"
    echo "destination: where you want the .deb packages and associated stuff"
    exit 1
fi

dest=$1
[ -d $dest ] || mkdir -p $dest
rm -f $dest/*
[[ $dest == /* ]] || dest=$PWD/$dest

pkg=xmlrpc++
version=0.7

tmpdir=$(mktemp -d /tmp/${pkg}_XXXXXX)
trap "{ rm -rf $tmpdir; exit; }" EXIT

# untar original tree
tar xzf ${pkg}${version}.tar.gz -C $tmpdir

# Debian requires hyphen between package name and version
mv $tmpdir/${pkg}${version} $tmpdir/${pkg}-${version}

# create .orig.tar.gz of tree with new path name
# Debian requires that name of tar has underscore
# between package name and version, instead of hyphen
# orig.tar.gz is in parent of tree
tar czf $tmpdir/${pkg}_${version}.orig.tar.gz \
    -C $tmpdir ${pkg}-${version}

# Create diff of original tree against new contents in subversion
diff -ruN --exclude=debian --exclude=.svn $tmpdir/${pkg}-${version} ${pkg} | \
    sed -e "
s,^--- $tmpdir/${pkg}-${version}/,--- a/,
s,^+++ xmlrpc++/,+++ b/," \
    > $tmpdir/$pkg.patch

# Copy debian files to tree
rsync -a $pkg/debian $tmpdir/${pkg}-${version}

cd $tmpdir/${pkg}-${version}

# different debian files for armel
# mv debian/xmlrpc++.install-armel debian/xmlrpc++.install
# mv debian/xmlrpc++-dev.install-armel debian/xmlrpc++-dev.install
# mv debian/xmlrpc++.symbols-armel debian/xmlrpc++.symbols

# import diff into one patch with quilt
export QUILT_PATCHES=debian/patches
mkdir -p $QUILT_PATCHES

quilt import ../$pkg.patch

# to apply patch
# quilt push
# to un-apply patch
# quilt pop

# -us: do not sign the source package
# -uc: do not sign the .changes file
export CC=arm-linux-gnueabi-gcc
debuild -aarmel -us -uc

# to grab the symbols from the built package:
cd ..
dpkg-deb -R ${pkg}_${version}-*_armel.deb ${pkg}_tmp
sed -e 's/0\.7-1/0\.7/' ${pkg}_tmp/DEBIAN/symbols \
    > xmlrpc++.symbols

rsync -v *.build *.changes *.deb *.debian.tar.xz *.dsc *.orig.tar.gz *.symbols $dest

# echo $tmpdir
