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
if [ "$mydist" == unknown ]; then
    echo "unknown distribution"
    exit 1
fi

doarm=false
which arm-linux-gcc > /dev/null 2>&1 && doarm=true

doarmbe=false
which armbe-linux-gcc > /dev/null 2>&1 && doarmbe=true

version=0.7
fversion=`echo $version | sed 's/\./_/g'`

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

archs=""
$doarm && archs="$archs arm"
$doarmbe && archs="$archs armbe"
rpmbuild --define "archs $archs" -ba --clean  xmlrpc++-cross.spec

rpaths=()

if [ -d $rroot ]; then
    # copy rpm for this distribution (fc8,el5,etc) to repositiory
    rpms=($topdir/RPMS/i386/xmlrpc++-${version}*.rpm)
    for r in ${rpms[*]}; do
        rpath=`get_repo_path_from_rpm $r
        [ -d $rroot/$rpath ] || mkdir -p $rroot/$rpath || exit
        rsync $r $rroot/$rpath
        rpaths=(${rpaths[*]} ${rpath%/*})
    done
    # copy source rpm for this distribution (fc8,el5,etc) to rroot
    rpms=($topdir/SRPMS/xmlrpc++-${version}*.rpm)
    for r in ${rpms[*]}; do
        rpath=`get_repo_path_from_rpm $r
        [ -d $rroot/$rpath ] || mkdir -p $rroot/$rpath || exit
        rsync $r $rroot/$rpath
        rpaths=(${rpaths[*]} ${rpath%/*})
    done

    # copy cross rpms to ael repositiory
    rpath=ael/1/i386
    [ -d $rroot/$rpath ] || mkdir -p $rroot/$rpath || exit
    rpms=($topdir/RPMS/i386/xmlrpc++-cross-*-${version}*.rpm)
    for r in ${rpms[*]}; do
        rsync $r $rroot/$rpath
    done
    rpaths=(${rpaths[*]} ${rpath%/*})

    # copy source rpms to ael repositiory
    rpath=ael/1/SRPMS
    rpms=($topdir/SRPMS/xmlrpc++-cross-${version}*.src.rpm)
    for r in ${rpms[*]}; do
        rsync $r $rroot/$rpath
    done
    rpaths=(${rpaths[*]} ${rpath%/*})

    # update repository metadata
    OLDIFS=$IFS
    IFS=$'\n'
    rpaths=(`echo "${rpaths[*]}" | sort -u`)
    IFS=$OLDIFS

    for d in ${rpaths[*]}; do
        cd $rroot/$d
        createrepo .
    done
fi

