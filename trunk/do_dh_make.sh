#!/bin/bash

# create a temporary build tree, and run dh_make there to
# create the template files under the debian directory

pkg=xmlrpc++
version=0.7

tmpdir=$(mktemp -d /tmp/${pkg}_XXXXXX)
# trap "{ rm -rf $tmpdir; exit; }" EXIT

# untar original tree
tar xzf ${pkg}${version}.tar.gz -C $tmpdir

# Add hyphen in resulting path between pkg and version
mv $tmpdir/${pkg}${version} $tmpdir/${pkg}-${version}

rsync -a --exclude debian --exclude .svn ${pkg}/ $tmpdir/${pkg}-${version}

# create tar.gz of tree with new path name and updated contents
tar czf $tmpdir/${pkg}_${version}.orig.tar.gz \
    -C $tmpdir ${pkg}-${version}

cd $tmpdir/${pkg}-${version}

dh_make -f ../${pkg}_${version}.orig.tar.gz

echo $tmpdir
exit
