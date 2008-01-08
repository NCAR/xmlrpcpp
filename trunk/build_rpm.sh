#!/bin/sh

# Build arm and armbe RPMs of xmlrpc++.

# To build an rpm we need the following:
# 1 tar of source
# 2 any necessary patches
# 3 .spec file
# The name of the tar and patches are specified in the .spec file.
# rpmbuild expects to find the tar and patches on %_topdir/SOURCES,
#   where %_topdir is defined in $HOME/.rpmmacros
# After copying the tar and patches to %_topdir/SOURCES,
# "rpmbuild -ba xxx.spec" is run with each spec file.
#
# Since other tar files and patches from other packages
# may be on %_topdir/SOURCES, the names of the tar and patches should
# contain the unique package name, like xmlrpc++_makefile.patch,
# and not just makefile.patch.

# set -x

doarm=false
which arm-linux-gcc > /dev/null 2>&1 && doarm=true

doarmbe=false
which armbe-linux-gcc > /dev/null 2>&1 && doarmbe=true

version=0.7
fversion=`echo $version | sed 's/\./_/g'`

needs_topdir=true

# Where to find user's rpm macro definitions
rmacs=~/.rpmmacros

[ -f $rmacs ] && grep -q "^[[:space:]]*%_topdir[[:space:]]" $rmacs && needs_topdir=false

if $needs_topdir; then
    mkdir -p ~/rpmbuild/{BUILD,RPMS,S{OURCE,PEC,RPM}S} || exit 1
    echo "\
%_topdir	%(echo \$HOME)/rpmbuild
# turn off building the debuginfo package
%debug_package	%{nil}\
" > $rmacs
fi

topdir=`rpm --eval %_topdir`

if [ `echo $topdir | cut -c 1` == "%" ]; then
    echo "%_topdir not defined in $rmacs"
    exit 1
fi

# untar the original source to /tmp, then create a patch by diffing
# the original against our updates.
tardest=/tmp/${0##*/}.$$
[ -d $tardest ] || mkdir $tardest
trap "{ rm -rf $tardest; exit; }" EXIT

tar xzf xmlrpc++${version}.tar.gz -C $tardest

# create the patch
diff -pruN --exclude .svn $tardest/xmlrpc++${version} xmlrpcpp > $tardest/xmlrpc++${version}.patch

# copy to SOURCES
rsync $tardest/*.patch xmlrpc++${version}.tar.gz $topdir/SOURCES

rpmbuild -ba --clean xmlrpc++.spec

if $doarm; then
    rpmbuild -ba --clean xmlrpc++-x-arm.spec
    # rpmbuild -ba --target=armv5tel --clean xmlrpc++-x-arm.spec
fi

if $doarmbe; then
    rpmbuild -ba --clean xmlrpc++-x-armbe.spec
    # rpmbuild -ba --target=armv5te --clean xmlrpc++-x-armbe.spec
fi

repo=/net/www/docs/software/rpms

if [ -d $repo ]; then

    rpms=($topdir/RPMS/i386/xmlrpc++-x-arm*-${version}*.rpm \
        $topdir/RPMS/i386/xmlrpc++-${version}*.rpm \
        $topdir/SRPMS/xmlrpc++-x-arm*-${version}*.src.rpm)

    for r in ${rpms[*]}; do
        rr=${r%.*}
        rr=${rr%.*}
        dist=${rr##*.}
        case $dist in
        fc7 | fc8)
            rsync $r $repo/$dist/RPMS
            ;;
        esac
    done

fi
