# makefile written for gnu make
CXX		?= g++
SRC		= ./src
SHARED		= -shared -Wl,-soname=libxmlrpcpp.so.0
CPPFLAGS	= -I$(SRC)
DEBUG		= -g
OPTIMIZE	= -O2
GCCWARN		= -Wall
CXXFLAGS	= $(DEBUG) $(GCCWARN) $(OPTIMIZE) $(INCLUDES) -fPIC
MAJOR		= 0
MINOR		= 7
VERSION         = $(MAJOR).$(MINOR)
# Set LIBDIR to lib64 on 64 bit systems
LIBDIR		= lib

DESTDIR		=
prefix		= /opt/local/nidas/x86
MKDIR		= mkdir -p
CP		= cp
LN		= ln -s

LIB		= ./libXmlRpcpp.a
SO              = ./libxmlrpcpp.so.$(VERSION)

# Add your system-dependent network libs here. These are
# only used to build the tests (your application will need them too).
# Linux: none
# Solaris: -lsocket -lnsl
#SYSTEMLIBS	= -lsocket -lnsl
SYSTEMLIBS	= -lpthread
LDLIBS		= $(LIB) $(SYSTEMLIBS)

OBJ		= $(SRC)/XmlRpcClient.o $(SRC)/XmlRpcDispatch.o \
		$(SRC)/XmlRpcServer.o $(SRC)/XmlRpcServerConnection.o \
		$(SRC)/XmlRpcServerMethod.o $(SRC)/XmlRpcSocket.o $(SRC)/XmlRpcSource.o \
		$(SRC)/XmlRpcUtil.o $(SRC)/XmlRpcValue.o

all:		$(LIB) $(SO) tests

$(LIB):		$(OBJ)
		$(AR) $(ARFLAGS) $(LIB) $(OBJ)

$(SO):          $(OBJ)
		$(CXX) -o $(SO) $(SHARED) $(OBJ)

tests:		$(LIB)
		cd test && $(MAKE) CXX=$(CXX) CXXFLAGS="$(CXXFLAGS)" SYSTEMLIBS="$(SYSTEMLIBS)"

doc doxygen:
		cd src && doxygen Doxyfile

clean:
		rm -f $(SRC)/*.o
		rm -f $(SRC)/*~
		rm -f $(LIB)
		cd test && $(MAKE) clean

install:
		$(MKDIR) $(DESTDIR)$(prefix)/$(LIBDIR)
		$(CP) $(SO) $(LIB) $(DESTDIR)$(prefix)/$(LIBDIR)
		$(MKDIR) $(DESTDIR)$(prefix)/$(LIBDIR)/pkgconfig
		sed -e 's,@PREFIX@,$(prefix),' -e 's,@LIBDIR@,$(LIBDIR),' xmlrpcpp.pc > \
			$(DESTDIR)$(prefix)/$(LIBDIR)/pkgconfig/xmlrpcpp.pc
		$(MKDIR) $(DESTDIR)$(prefix)/include/xmlrpcpp
		$(CP) src/*.h $(DESTDIR)$(prefix)/include/xmlrpcpp
		( cd $(DESTDIR)$(prefix)/$(LIBDIR); rm -f libxmlrpcpp.so libxmlrpcpp.so.$(MAJOR); $(LN) $(SO) libxmlrpcpp.so;  $(LN) $(SO) libxmlrpcpp.so.$(MAJOR); )
		# Does not install tests right now	

# Debian package make target, in case you want to manually build a package
# from the distribution.
deb:
		dpkg-buildpackage -rfakeroot
