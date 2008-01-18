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

get_mydist() {
    local rrel=/etc/redhat-release
    local dist="unknown"
    if [ -f $rrel ]; then
        n=`sed 's/^.*release *\([0-9]*\).*/\1/' $rrel`
        if fgrep -q Enterprise $rrel; then
            dist=el$n
        elif fgrep -q CentOS $rrel; then
            dist=el$n
        elif fgrep -q Fedora $rrel; then
            dist=fc$n
        fi
        case `uname -i` in
        x86_64)
            dist=${dist}_64
            ;;
        *)
            ;;
        esac
    fi
    echo $dist
}
mydist=`get_mydist`
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

archs=""
$doarm && archs="$archs arm"
$doarmbe && archs="$archs armbe"
rpmbuild --define "archs $archs" -ba --clean  xmlrpc++-cross.spec

repo=/net/www/docs/software/rpms


dists=()

if [ -d $repo ]; then
    # copy rpm for this distribution (fc8,el5,etc) to repositiory
    rpms=($topdir/RPMS/i386/xmlrpc++-${version}*.rpm)
    for r in ${rpms[*]}; do
        rr=${r%.*}
        rr=${rr%.*}
        dist=${rr##*.}
        case $dist in
        fc*)
            ;;
        *)
            dist=$mydist
            ;;
        esac
        [ -d $repo/$dist/RPMS ] || mkdir -p $repo/$dist/RPMS || exit
        [ -d $repo/$dist/SRPMS ] || mkdir -p $repo/$dist/SRPMS || exit
        rsync $r $repo/$dist/RPMS
        dists=(${dists[*]} $dist)
    done
    # copy source rpm for this distribution (fc8,el5,etc) to repositiory
    rpms=($topdir/SRPMS/xmlrpc++-${version}*.rpm)
    for r in ${rpms[*]}; do
        rr=${r%.*}
        rr=${rr%.*}
        dist=${rr##*.}
        case $dist in
        fc*)
            ;;
        *)
            dist=$mydist
            ;;
        esac
        [ -d $repo/$dist/RPMS ] || mkdir -p $repo/$dist/RPMS || exit
        [ -d $repo/$dist/SRPMS ] || mkdir -p $repo/$dist/SRPMS || exit
        rsync $r $repo/$dist/SRPMS
        dists=(${dists[*]} $dist)
    done

    # copy cross rpms to ael repositiory
    dist=ael
    [ -d $repo/$dist/RPMS ] || mkdir -p $repo/$dist/RPMS || exit
    [ -d $repo/$dist/SRPMS ] || mkdir -p $repo/$dist/SRPMS || exit
    rpms=($topdir/RPMS/i386/xmlrpc++-cross-*-${version}*.rpm)
    for r in ${rpms[*]}; do
        rsync $r $repo/$dist/RPMS
    done

    # copy source rpms to ael repositiory
    rpms=($topdir/SRPMS/xmlrpc++-cross-${version}*.src.rpm)
    for r in ${rpms[*]}; do
        rsync $r $repo/$dist/SRPMS
    done
    dists=(${dists[*]} $dist)

    # update repository metadata
    OLDIFS=$IFS
    IFS=$'\n'
    dists=(`echo "${dists[*]}" | sort -u`)
    IFS=$OLDIFS

    for d in ${dists[*]}; do
        cd $repo/$d
        createrepo .
    done
fi

