Summary:    A C++ implementation of the XML-RPC protocol
Name:   xmlrpc++
Version:    0.7
Release:    6%{?dist}
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
%{__make} CXXFLAGS="${RPM_OPT_FLAGS} -fPIC" prefix=%{_prefix}

%install
%{__rm} -rf $RPM_BUILD_ROOT
%{__make} install LIBDIR=%{_lib} prefix="$RPM_BUILD_ROOT%{_prefix}"

install -d $RPM_BUILD_ROOT%{_libdir}/pkgconfig

cat << \EOD > $RPM_BUILD_ROOT%{_libdir}/pkgconfig/xmlrpcpp.pc
prefix=/usr
exec_prefix=/usr
libdir=%{_libdir}
includedir=/usr/include

Name: xmlrpcpp
Description: A C++ implementation of the XML-RPC protocol
Version: 0.7
Libs: -lxmlrpcpp
Cflags: -I${includedir}/xmlrpcpp
EOD

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%{_libdir}/libXmlRpcpp.a
%{_libdir}/libxmlrpcpp.so
%{_libdir}/libxmlrpcpp.so.*
%{_includedir}/xmlrpcpp/
%config %{_libdir}/pkgconfig/xmlrpcpp.pc

%pre
# nuke old libraries and headers
rm -rf %{_includedir}/xmlrpc++
rm -f %{_libdir}/libXmlRpc.a 
rm -f %{_libdir}/libxmlrpc++.so.%{version}

%post
ldconfig

%changelog
* Mon Dec  5 2011 Gordon Maclean <maclean@ucar.edu> 0.7-6
- XmlRpcDispatch::work calls pselect with SIGUSR1 unblocked.
- If SIGUSR1 is otherwise blocked in the thread, then it will
- be caught by the pselect.
- Added pkg-config file.
* Tue Jun 15 2010 Gordon Maclean <maclean@ucar.edu> 0.7-5
- When building libxmlrpcpp.so.0.7 set the -soname to libxmlrpcpp.so.0.
- Useful doc: http://www.ibm.com/developerworks/library/l-shobj
- objdump -p dumps the SONAME, and by convention it should be libname.so.MAJOR
- When rpm builds dependencies (find-requires, find-provides) of shared
- libraries it uses the SONAME.
* Mon Apr 23 2009 Gordon Maclean <maclean@ucar.edu> 0.7-4
- Changed name of library to libxmlrpcpp.so to avoid conflict
- with xmlrpc-c package. Header files in /usr/include/xmlrpcpp
* Tue Apr 29 2008  Gary Granger  <granger@ucar.edu> 0.7-3
	Compiler fixes for Fedora 9
* Wed Apr 9 2008 Charlie Martin <martinc@ucar.edu> 0.7-2
* Wed Apr 9 2008 Charlie Martin <martinc@ucar.edu> 0.7-2
* Mon Dec 24 2007 Gordon Maclean <maclean@ucar.edu> 0.7-1
- RPM of xmlrpc++
