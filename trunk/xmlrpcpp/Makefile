# makefile written for gnu make
CXX		= g++
SRC		= ./src
SHARED		= -shared
CPPFLAGS	= -I$(SRC)
DEBUG		= -g
OPTIMIZE	= -O2
GCCWARN		= -Wall
CXXFLAGS	= $(DEBUG) $(GCCWARN) $(OPTIMIZE) $(INCLUDES) -fPIC
VERSION         = 0.7
# Set LIBDIR to lib64 on 64 bit systems
LIBDIR		= lib

DESTDIR		=
prefix		= /opt/local/nidas/x86
MKDIR		= mkdir -p
CP		= cp
LN		= ln -s

LIB		= ./libXmlRpc.a
SO              = ./libxmlrpc++.so.$(VERSION)

# Add your system-dependent network libs here. These are
# only used to build the tests (your application will need them too).
# Linux: none
# Solaris: -lsocket -lnsl
#SYSTEMLIBS	= -lsocket -lnsl
SYSTEMLIBS	=
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
		$(MKDIR) $(DESTDIR)$(prefix)/include/xmlrpc++
		$(CP) src/*.h $(DESTDIR)$(prefix)/include/xmlrpc++
		( cd $(DESTDIR)$(prefix)/$(LIBDIR); rm -f libxmlrpc++.so; $(LN) $(SO) libxmlrpc++.so )
		# Does not install tests right now	

# Debian package make target, in case you want to manually build a package
# from the distribution.
deb:
		dpkg-buildpackage -rfakeroot
