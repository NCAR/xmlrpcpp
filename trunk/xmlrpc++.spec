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
%{__make} CXXFLAGS="${RPM_OPT_FLAGS}" prefix=%{_prefix}

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
- RPM of xmlrpc++