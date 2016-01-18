#!/bin/sh

# install a package to a debian repository

# debian terms used by reprepro:
# component: main contrib non-free
# type: dsc|deb|udeb
# codename: jessie

# set -x

pkg=$1
pdir=${pkg%/*}
pnodir=${pkg##*/}
pnodeb=${pnodir%.deb}
pnoarch=${pnodeb%_*}
pnover=${pnoarch%_*}

repo=/net/www/docs/software/debian
[ $# -gt 1 ] && repo=$2

# reprepro -V -b $repo includedeb jessie $pkg.deb

# reprepro -V -b $repo includedsc jessie $pkg.dsc

# reprepro -V -b $repo -A "armel|source" include jessie $pkg.changes

reprepro -V -b $repo -A "armel|source" list jessie $pnover
reprepro -V -b $repo -A "armel|source" remove jessie $pnover

reprepro -V -b $repo -A "armel|source" include jessie $pdir/$pnodeb.changes

