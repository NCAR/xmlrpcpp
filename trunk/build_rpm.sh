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

# Get the repo_funcs in eol/repo/scripts
source ../../../repo/scripts/repo_funcs.sh

topdir=`get_rpm_topdir`
rroot=`get_eol_repo_root`

pkg=xmlrpc++
version=0.7
fversion=`echo $version | sed 's/\./_/g'`

doarm=false
which arm-linux-gcc > /dev/null 2>&1 && doarm=true

doarmbe=false
which armbe-linux-gcc > /dev/null 2>&1 && doarmbe=true

# untar the original source to /tmp, then create a patch by diffing
# the original against our updates.
tardest=/tmp/${0##*/}.$$
[ -d $tardest ] || mkdir $tardest
trap "{ rm -rf $tardest; exit; }" EXIT

tar xzf ${pkg}${version}.tar.gz -C $tardest

# create the patch
diff -pruN --exclude .svn $tardest/${pkg}${version} xmlrpcpp > $tardest/${pkg}${version}.patch

# copy to SOURCES
rsync $tardest/*.patch ${pkg}${version}.tar.gz $topdir/SOURCES

archs=""
$doarm && archs="$archs arm"
$doarmbe && archs="$archs armbe"

rpmbuild --define "archs $archs" -ba --clean  ${pkg}-cross.spec

rpmbuild -ba --clean ${pkg}.spec

if [ -d $rroot ]; then
    # copy rpm for this architecture and source rpm to repositiory
    arch=`uname -i`
    rpms=($topdir/RPMS/$arch/${pkg}-${version}*.$arch.rpm \
            $topdir/SRPMS/${pkg}-${version}*.src.rpm)
    copy_rpms_to_eol_repo ${rpms[*]}

    # Only copy cross packages for i386
    if [ $arch == i386 ]; then
        rpms=($topdir/RPMS/i386/${pkg}-cross-*-${version}*.rpm \
            $topdir/SRPMS/${pkg}-cross-${version}*.src.rpm)
        copy_ael_rpms_to_eol_repo ${rpms[*]}
    fi
fi

