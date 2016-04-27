#!/bin/sh

# Build x86, arm and armbe RPMs of xmlrpc++.

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

topdir=${TOPDIR:-$(rpmbuild --eval %_topdir)_$(hostname)}

sourcedir=$(rpm --define "_topdir $topdir" --eval %_sourcedir)
[ -d $sourcedir ] || mkdir -p $sourcedir

pkg=xmlrpc++
version=0.7
fversion=`echo $version | sed 's/\./_/g'`

get_release() 
{
    # discard M,S,P, mixed versions
    v=$(svnversion . | sed 's/:.*$//' | sed s/[A-Z]//g)
    [ $v == exported ] && v=1
    echo $v
}

# jenkins sets SVN_REVISION
release=${SVN_REVISION:=$(get_release)}
doarm=false
which arm-linux-gcc > /dev/null 2>&1 && doarm=true

doarmbe=false
which armbe-linux-gcc > /dev/null 2>&1 && doarmbe=true

# untar the original source to /tmp, then create a patch by diffing
# the original against our updates.
tardest=$(mktemp -d /tmp/${0##*/}_XXXXXX)
trap "{ rm -rf $tardest; exit; }" EXIT

tar xzf ${pkg}${version}.tar.gz -C $tardest

# create the patch
diff -pruN --exclude .svn $tardest/${pkg}${version} xmlrpcpp > $tardest/${pkg}${version}.patch

# copy to SOURCES
rsync $tardest/*.patch ${pkg}${version}.tar.gz $sourcedir

archs=""
$doarm && archs="$archs arm"
$doarmbe && archs="$archs armbe"

# not sure why, but the rpath check in rpmbuild hangs forever on shiraz
# if [ $(hostname) == shiraz.eol.ucar.edu ]; then
#     export QA_SKIP_RPATHS=true
# fi

if [ -n "$archs" ]; then
    rpmbuild --define "archs $archs" --target i386 \
        --define "debug_package %{nil}" \
        --define "release $release"  \
        --define "_topdir $topdir"  \
        -ba --clean  ${pkg}-cross.spec || exit 1
fi

rpmbuild -ba --clean \
    --define "debug_package %{nil}" \
    --define "release $release"  \
    --define "_topdir $topdir"  \
    ${pkg}.spec || exit 1

