Summary:    A C++ implementation of the XML-RPC protocol
Name:   xmlrpc++
Version:    0.7
Release:    1%{?dist}
License:    GPL
Group:      System Environment/Libraries
URL:        http://xmlrpcpp.sourceforge.net
Source:     %{name}%{version}.tar.gz
Patch0:     %{name}%{version}.patch
BuildRoot:  %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

# Use rpmbuild --target=armv5tel to build this package
# See possible target/architecture strings in /usr/lib/rpm/rpmrc
ExclusiveArch:  armv5te
# note: no -g option
%define optflags -O2 -march=armv4t

%define _use_internal_dependency_generator     0

# Override where the libraries and header files are installed
%define _prefix /opt/local/arm
# %_libdir /opt/local/arm/lib
# %_includedir /opt/local/arm/lib
%{echo:"_prefix=%{_prefix}\n"}
%{echo:_libdir=%{_libdir}}
%define debug_package %{nil}

%description
XmlRpc++ is a C++ implementation of the XML-RPC protocol. It is based upon
Shilad Sen's excellent py-xmlrpc. The XmlRpc protocol was designed to make
remote procedure calls easy: it encodes data in a simple XML format and uses
HTTP for communication. XmlRpc++ is designed to make it easy to incorporate
XML-RPC client and server support into C++ applications.

%prep
%setup -q -n xmlrpc++0.7
%patch0 -p1

%build
%{__make} CXXFLAGS="${RPM_OPT_FLAGS}" CXX=armbe-linux-g++ prefix=%{_prefix}

%install
%{__make} install prefix="$RPM_BUILD_ROOT%{_prefix}"

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%{_libdir}/libXmlRpc.a
%{_libdir}/libxmlrpc++.so.%{version}
%{_libdir}/libxmlrpc++.so
%{_includedir}/xmlrpc++/

%changelog

* Mon Dec 24 2007 Gordon Maclean <maclean@ucar.edu> 0.7-1
- RPM of cross compiled xmlrpc++ for arm
