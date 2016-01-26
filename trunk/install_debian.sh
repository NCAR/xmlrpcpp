#!/bin/sh

# install a package to a debian repository

repo=/net/www/docs/software/debian
repo=/net/ftp/pub/temp/users/maclean/debian

if [ $# -lt 1 ]; then
    echo "Usage: ${0##*/} changes_file [repo]"
    echo "default repo=$repo"
    exit 1
fi

# debian terms used by reprepro:
# component: main contrib non-free
# type: dsc|deb|udeb
# codename: jessie

changes=$1
[ $# -gt 1 ] && repo=$2

# get list of binary packages from .changes file
pkgs=$(grep "^Binary:" $changes | sed -e s/Binary://)

# allow group write
umask 0002

archs=$(grep "^Architecture:" $changes | sed -e 's/Architecture: *//' | tr \  "|")

flock $repo reprepro -b $repo deleteunreferenced

flock $repo reprepro -V -b $repo -A "$archs" remove jessie $pkgs

flock $repo reprepro -V -b $repo -A "$archs" include jessie $changes

