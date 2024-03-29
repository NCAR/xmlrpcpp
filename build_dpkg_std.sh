#!/bin/bash

# Build source and binary debian packages of xmlrpc++

usage() {
    echo "Usage: ${0##*/} [--no-sign] destination arch"
    echo "destination: where you want the .deb packages and associated stuff"
    echo "arch: amd64, armel or armhf"
    exit 1
}

dest=""
arch=""
sign=1
while [ $# -gt 0 ]; do

    case "$1" in

        --no-sign)
            sign=0;;

        -*)
            echo "Unrecognized option: $1"
            usage
            ;;

        *)
            if [ -z "$dest" ]; then
                dest="$1"
            elif [ -z "$arch" ]; then
                arch="$1"
            else
                echo "Too many arguments."
                usage
            fi
            ;;

    esac
    shift

done

if [ -z "$dest" -o -z "$arch" ]; then
    usage
fi

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
[ "$arch" == armel ] && export CC=arm-linux-gnueabi-gcc

# Since we're also installing the source package with reprepro,
# it seems we need to specify -sa here to force the inclusion
# of the orig.tar.gz in the changes file. Not sure why it isn't
# the default.
key="-sa -k'<eol-prog@eol.ucar.edu>'"
if [ $sign -eq 0 ]; then
    key="-us -uc"
fi
debuild -a$arch $key

# ls debian

cd ..

# to grab the symbols from the built package:
# dpkg-deb -R ${pkg}_${version}-*_${arch}.deb ${pkg}_tmp
# sed -e 's/0\.7-1/0\.7/' ${pkg}_tmp/DEBIAN/symbols \
#     > xmlrpc++.symbols

rsync -v *.build *.changes *.deb *.debian.tar.xz *.dsc *.orig.tar.gz $dest

# echo $tmpdir
