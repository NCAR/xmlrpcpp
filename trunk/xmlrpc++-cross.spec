
# -*- Mode: rpm-spec -*-

# Default architectures to build.
# Override with:
#   $ rpmbuild --define "archs arm" ...
# %define default_archs arm armbe i386
# %define default_archs arm armbe
%define default_archs arm armbe

%{!?archs:%global archs %{default_archs}}

%define building_arch() %(r=0; for A in %{archs}; do if [ ${A} == %1 ]; then r=1; fi; done; echo ${r})

%define cross_os linux
%define cross_target %{cross_arch}-%{cross_os}

%define prefix /opt/arcom

%define xname xmlrpc++

Summary:    A C++ implementation of the XML-RPC protocol build for %{archs}
Name:       %{xname}-cross
Version:    0.7
Release:    1
License:    GPL
Group:      Development/Libraries
URL:        http://xmlrpcpp.sourceforge.net
Source:     %{xname}%{version}.tar.gz
Patch0:     %{xname}%{version}.patch
BuildRoot:  %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

%description
XmlRpc++ is a C++ implementation of the XML-RPC protocol. It is based upon
Shilad Sen's excellent py-xmlrpc. The XmlRpc protocol was designed to make
remote procedure calls easy: it encodes data in a simple XML format and uses
HTTP for communication. XmlRpc++ is designed to make it easy to incorporate
XML-RPC client and server support into C++ applications.

%define cross_arch arm
%package -n %{name}-%{cross_target}
Summary:        %{name} headers and shareable libraries for %{cross_target}
Group:          Development/Libraries
%description -n %{name}-%{cross_target}
This package contains the headers and shareable libraries of %{name} for %{cross_target}.

%define cross_arch armbe
%package -n %{name}-%{cross_target}
Summary:        %{name} headers and shareable libraries for %{cross_target}
Group:          Development/Libraries
AutoReqProv:    no
%description -n %{name}-%{cross_target}
This package contains the headers and shareable libraries of %{name} for %{cross_target}.

%prep
%setup -q -n xmlrpc++0.7
%patch0 -p1

%build

THIS_BUILD_DIR="$PWD"
for a in %{archs} ; do
   case $a in
    arm)
            cflags="-O2 -march=armv5te"
            ;;
    armbe)
            cflags="-O2 -march=armv4t"
            ;;
    *)
            echo "architecture $a not supported"
            exit 1
            ;;
    esac

    CROSS_TARGET=${a}-%{cross_os}
    ARCH_BUILD_DIR=${THIS_BUILD_DIR}/build_${CROSS_TARGET}
    if [ -d ${ARCH_BUILD_DIR} ]; then
            rm -rf  ${ARCH_BUILD_DIR}
    fi
    mkdir -p ${ARCH_BUILD_DIR}

    %{__make} CXXFLAGS="${cflags}" CXX=${a}-linux-g++
    %{__make} install prefix=${ARCH_BUILD_DIR}
    %{__make} clean
done


%install

THIS_BUILD_DIR="$PWD"

for a in %{archs} ; do
    CROSS_TARGET=${a}-%{cross_os}
    ARCH_BUILD_DIR=${THIS_BUILD_DIR}/build_${CROSS_TARGET}
    cd $ARCH_BUILD_DIR

    install -d ${RPM_BUILD_ROOT}%{prefix}/$CROSS_TARGET
    cp -r include ${RPM_BUILD_ROOT}%{prefix}/$CROSS_TARGET
    cp -r lib ${RPM_BUILD_ROOT}%{prefix}/${CROSS_TARGET}


    cat <<__EOF__ > files
%defattr(-, root, root)
%define __strip ${a}-linux-strip
%{prefix}/${CROSS_TARGET}/include/xmlrpc++
%{prefix}/${CROSS_TARGET}/lib/libXmlRpc.a
%{prefix}/${CROSS_TARGET}/lib/libxmlrpc++.so.%{version}
%{prefix}/${CROSS_TARGET}/lib/libxmlrpc++.so
__EOF__
done

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%define cross_arch arm
%if %building_arch %{cross_arch}
%files -n %{name}-%{cross_target} -f build_%{cross_target}/files
%endif

%define cross_arch armbe
%if %building_arch %{cross_arch}
%files -n %{name}-%{cross_target} -f build_%{cross_target}/files
%endif

%changelog

* Mon Dec 24 2007 Gordon Maclean <maclean@ucar.edu> 0.7-1
- RPM of cross compiled xmlrpc++ for %{archs}
