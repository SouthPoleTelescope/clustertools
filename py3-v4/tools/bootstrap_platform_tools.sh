#!/bin/sh

# Usage: bootstrap_platform_tools.sh scratchdir

JFLAG=-j8

# Versions and tools
GCCVER=9.3.0
BINUTILSVER=2.30
MPCVER=1.1.0
MPFRVER=4.0.2
GMPVER=6.2.0

PYVER=3.8.2
PYSETUPTOOLSVER=46.1.1
PIPVER=20.0.2
BOOSTVER=1.72.0
HDF5VER=1.12.0
NETCDFVER=4.7.3
NETCDFCXXVER=4.3.0
FFTWVER=3.3.8
GSLVER=2.6

GNUPLOTVER=5.2.8
PGPLOTVER=5.2.2
TCLVER=8.6.10
BZIPVER=1.0.6
ZLIBVER=1.2.11 # NB: built conditionally
CMAKEVER=3.17.0
FLACVER=1.3.2
FREETYPEVER=2.9.1
CFITSIOVER=3.47
OPENBLASVER=0.3.9
SUITESPARSEVER=5.7.1

HEALPIXVER=3.60_2019Dec18
LENSPIXVER=3c76223024f91f693e422ae89cb1cf2e81e061da
SPICEVER=v03-06-04

# Below is a frozen version of (order is important in some cases) as of 3/23/20:
# pip install wheel rst2html5 numpy scipy tornado ipython pyfits numexpr matplotlib xhtml2pdf Sphinx tables urwid pyFFTW spectrum SQLAlchemy PyYAML ephem idlsave ipdb jsonschema memory_profiler simplejson joblib lmfit camb==1.1.1 h5py pandas astropy healpy==1.13.0 jupyter
PYTHON_PKGS_TO_INSTALL="alabaster==0.7.12 asteval==0.9.18 astropy==4.0 attrs==19.3.0 Babel==2.8.0 backcall==0.1.0 bleach==3.1.3 camb==1.1.1 certifi==2019.11.28 chardet==3.0.4 cycler==0.10.0 decorator==4.4.2 defusedxml==0.6.0 docutils==0.16 entrypoints==0.3 ephem==3.7.7.1 Genshi==0.7.3 h5py==2.10.0 healpy==1.13.0 html5lib==1.0.1 IDLSave==1.0.0 idna==2.9 imagesize==1.2.0 ipdb==0.13.2 ipykernel==5.2.0 ipython==7.13.0 ipython-genutils==0.2.0 ipywidgets==7.5.1 jedi==0.16.0 Jinja2==2.11.1 joblib==0.14.1 jsonschema==3.2.0 jupyter==1.0.0 jupyter-client==6.1.0 jupyter-console==6.1.0 jupyter-core==4.6.3 kiwisolver==1.1.0 lmfit==1.0.0 MarkupSafe==1.1.1 matplotlib==3.2.1 memory-profiler==0.57.0 mistune==0.8.4 mpmath==1.1.0 nbconvert==5.6.1 nbformat==5.0.4 notebook==6.0.3 numexpr==2.7.1 numpy==1.18.2 packaging==20.3 pandas==1.0.3 pandocfilters==1.4.2 parso==0.6.2 pexpect==4.8.0 pickleshare==0.7.5 Pillow==7.0.0 prometheus-client==0.7.1 prompt-toolkit==3.0.4 psutil==5.7.0 ptyprocess==0.6.0 pyFFTW==0.12.0 pyfits==3.5 Pygments==2.0.2 pyparsing==2.4.6 PyPDF2==1.26.0 pyrsistent==0.15.7 python-dateutil==2.8.1 pytz==2019.3 PyYAML==5.3.1 pyzmq==19.0.0 qtconsole==4.7.1 QtPy==1.9.0 reportlab==3.5.42 requests==2.23.0 rst2html5==1.10.3 scipy==1.4.1 Send2Trash==1.5.0 simplejson==3.17.0 six==1.14.0 snowballstemmer==2.0.0 spectrum==0.7.6 Sphinx==2.4.4 sphinxcontrib-applehelp==1.0.2 sphinxcontrib-devhelp==1.0.2 sphinxcontrib-htmlhelp==1.0.3 sphinxcontrib-jsmath==1.0.1 sphinxcontrib-qthelp==1.0.3 sphinxcontrib-serializinghtml==1.1.4 SQLAlchemy==1.3.15 sympy==1.5.1 tables==3.6.1 terminado==0.8.3 testpath==0.4.4 tornado==6.0.4 traitlets==4.3.3 uncertainties==3.1.2 urllib3==1.25.8 urwid==2.1.0 wcwidth==0.1.9 webencodings==0.5.1 widgetsnbextension==3.5.1 xhtml2pdf==0.2.4"

# Extra things for grid tools
GLOBUSVER=6.0.1493989444
#GFALVER=2.17.2 # Has DEPENDENCIES

# ----------------- Installation---------------------

# Figure out how to download things
if wget -q -O /dev/null http://www.google.com; then
	FETCH () {
		test -f `basename $1` || wget --no-check-certificate $1
	}
elif curl -Ls -o /dev/null http://www.google.com; then
	FETCH () {
		test -f `basename $1` || curl -kLO $1
	}
elif fetch -o /dev/null http://www.google.com; then
	FETCH () {
		test -f `basename $1` || fetch $1
	}
else
	echo "Cannot figure out how to download things!"
	exit 1
fi

# figure out how to replace text
TESTFILE=$(mktemp)
echo "test" > $TESTFILE
if sed -i 's/test/TEST/g' $TESTFILE; then
	SEDI () {
		sed -i "$1" $2
	}
elif sed -e 's/test/TEST/g' -i '' $TESTFILE; then
	SEDI () {
		sed -e "$1" -i '' $2
	}
else
	echo "Cannot figure out how to replace text!"
	exit 1
fi

set -e 
trap "echo Build Error" EXIT

mkdir -p $SROOT
mkdir -p $1

mkdir -p $SROOT/lib
ln -s $SROOT/lib $SROOT/lib64

# Compiler first
if [ ! -f $SROOT/bin/gcc ]; then
	unset CC
	unset CXX
	unset FC

	cd $1
	FETCH http://gmplib.org/download/gmp/gmp-$GMPVER.tar.bz2
	tar xjvf gmp-$GMPVER.tar.bz2
	cd gmp-$GMPVER
	./configure --prefix=$SROOT
	make $JFLAG; make install

	cd $1
	FETCH http://www.mpfr.org/mpfr-$MPFRVER/mpfr-$MPFRVER.tar.gz
	tar xvzf mpfr-$MPFRVER.tar.gz
	cd mpfr-$MPFRVER
	./configure --prefix=$SROOT --with-gmp-include=$SROOT/include --with-gmp-lib=$SROOT/lib
	make $JFLAG; make install

	cd $1
	FETCH ftp://ftp.gnu.org/gnu/mpc/mpc-$MPCVER.tar.gz
	tar xvzf mpc-$MPCVER.tar.gz
	cd mpc-$MPCVER
	./configure --prefix=$SROOT --with-gmp-include=$SROOT/include --with-gmp-lib=$SROOT/lib
	make $JFLAG; make install

	cd $1
	FETCH http://ftp.gnu.org/gnu/binutils/binutils-$BINUTILSVER.tar.gz
	tar xvzf binutils-$BINUTILSVER.tar.gz
	cd binutils-$BINUTILSVER
	./configure --prefix=$SROOT --disable-gprof --with-gmp-include=$SROOT/include --with-gmp-lib=$SROOT/lib
	make $JFLAG; make install

	cd $1
	FETCH http://www.netgull.com/gcc/releases/gcc-$GCCVER/gcc-$GCCVER.tar.gz
	tar xvzf gcc-$GCCVER.tar.gz
	cd gcc-$GCCVER
	# Subshell here prevents some kind of space madness on RHEL6
	(LD=`which ld` AS=`which as` LD_FOR_TARGET=`which ld` ./configure --prefix=$SROOT --with-gmp=$SROOT --disable-multilib --enable-languages=c,c++,fortran)
	if [ "`uname -s`" = FreeBSD ]; then
		gmake $JFLAG; gmake install
	else
		make $JFLAG; make install
	fi

	export CC=$SROOT/bin/gcc
	export CXX=$SROOT/bin/g++
	export FC=$SROOT/bin/gfortran
fi

# Bzip2
if [ ! -f $SROOT/bin/bzip2 ]; then
	cd $1
	FETCH http://distfiles.gentoo.org/distfiles/bzip2-$BZIPVER.tar.gz
	tar xvzf bzip2-$BZIPVER.tar.gz
	cd bzip2-$BZIPVER
	make install PREFIX=$SROOT
	make clean
	make -f Makefile-libbz2_so PREFIX=$SROOT
	cp libbz2.so.1.0.6 libbz2.so.1.0 $SROOT/lib
	cd $SROOT/lib
	ln -s libbz2.so.1.0 libbz2.so
fi

# Zlib
if [ ! -f $SROOT/lib/libz.so -a ! -f /usr/include/zlib.h ]; then
	cd $1
	FETCH http://zlib.net/zlib-$ZLIBVER.tar.gz
	tar xzvf zlib-$ZLIBVER.tar.gz
	cd zlib-$ZLIBVER
	./configure --prefix=$SROOT
	make $JFLAG
	make install
fi

# TCL/TK
if [ ! -f $SROOT/bin/tclsh ]; then
	cd $1
	FETCH http://liquidtelecom.dl.sourceforge.net/project/tcl/Tcl/$TCLVER/tcl$TCLVER-src.tar.gz
	FETCH http://liquidtelecom.dl.sourceforge.net/project/tcl/Tcl/$TCLVER/tk$TCLVER-src.tar.gz
	tar xvzf tcl$TCLVER-src.tar.gz
	tar xvzf tk$TCLVER-src.tar.gz
	cd tcl$TCLVER/unix
	./configure --prefix=$SROOT --disable-shared
	make $JFLAG
	make install install-libraries
	cd $1
	cd tk$TCLVER/unix
	# TK is an optional dependency
	(./configure --prefix=$SROOT && make && make install) || true
	ln -s $SROOT/bin/tclsh8.6 $SROOT/bin/tclsh
fi

# Python 3.7+ requires OpenSSL >= 1.0.2 and libffi, which certain
# ancient OSes (RHEL6) don't have. That seems to be the only one we
# care about, so use a lazy test.
if (echo $OS_ARCH | grep -q RHEL_6); then
	OPENSSLVER=1.1.1e
	FFIVER=3.3

	if [ ! -r $SROOT/lib/libcrypto.so ]; then
		cd $1
		FETCH https://www.openssl.org/source/openssl-$OPENSSLVER.tar.gz
		tar xvzf openssl-$OPENSSLVER.tar.gz
		cd openssl-$OPENSSLVER
		./config --prefix=$SROOT
		make $JFLAG
		make install
	fi
	if [ ! -r $SROOT/lib/libffi.so ]; then
		cd $1
		FETCH ftp://sourceware.org/pub/libffi/libffi-$FFIVER.tar.gz
		tar xvzf libffi-$FFIVER.tar.gz
		cd libffi-$FFIVER
		./configure --prefix=$SROOT
		make $JFLAG
		make install
	fi
fi

# Python
if [ ! -f $SROOT/bin/python ]; then
	cd $1
	FETCH http://www.python.org/ftp/python/$PYVER/Python-$PYVER.tgz
	tar xvzf Python-$PYVER.tgz
	cd Python-$PYVER
	./configure --prefix=$SROOT --enable-shared
	make $JFLAG
	make install

	# Make some symlinks that python should make but doesn't
	PYSHORTVER=`echo $PYVER | cut -d . -f 1,2`
	ln -s $SROOT/bin/python3 $SROOT/bin/python
	ln -s $SROOT/bin/python3-config $SROOT/bin/python-config
	ln -s $SROOT/lib/pkgconfig/python3.pc $SROOT/lib/pkgconfig/python.pc
	ln -s $SROOT/include/python${PYSHORTVER}m $SROOT/include/python${PYSHORTVER}
	if [ $(uname -s) == Darwin ]; then
		ln -s $SROOT/lib/libpython${PYSHORTVER}m.dylib $SROOT/lib/libpython${PYSHORTVER}.dylib
	fi
fi

# Python Setuptools
if python -c 'import setuptools'; then
	true
else
	cd $1
	FETCH https://files.pythonhosted.org/packages/source/s/setuptools/setuptools-$PYSETUPTOOLSVER.tar.gz
	tar xvzf setuptools-$PYSETUPTOOLSVER.tar.gz
	cd setuptools-$PYSETUPTOOLSVER
	python setup.py build
	python setup.py install --prefix=$SROOT
fi

# Pip
if [ ! -f $SROOT/bin/pip ]; then
	cd $1
	FETCH https://files.pythonhosted.org/packages/source/p/pip/pip-$PIPVER.tar.gz
	tar xvzf pip-$PIPVER.tar.gz
	cd pip-$PIPVER
	python setup.py build
	python setup.py install --prefix=$SROOT
fi

# Boost
if [ ! -r $SROOT/lib/libboost_python.so ]; then
	cd $1
	tarball=boost_`echo $BOOSTVER | tr . _`
	FETCH http://liquidtelecom.dl.sourceforge.net/project/boost/boost/$BOOSTVER/$tarball.tar.bz2
	tar xvjf $tarball.tar.bz2
	cd $tarball
	./bootstrap.sh --prefix=$SROOT --with-python=$SROOT/bin/python --with-python-root=$SROOT
	./b2 $JFLAG
	./b2 install

	ln -s $SROOT/lib/libboost_python38.so $SROOT/lib/libboost_python3.so
	ln -s $SROOT/lib/libboost_python3.so $SROOT/lib/libboost_python.so
fi

# CMake
if [ ! -f $SROOT/bin/cmake ]; then
	cd $1
	FETCH http://cmake.org/files/v$(echo $CMAKEVER | cut -f 1,2 -d .)/cmake-$CMAKEVER.tar.gz
	tar xvzf cmake-$CMAKEVER.tar.gz
	cd cmake-$CMAKEVER
	./configure --prefix=$SROOT
	make $JFLAG; make install
fi

# OpenBLAS
if [ ! -h $SROOT/lib/libblas.so ]; then
	cd $1
	FETCH http://github.com/xianyi/OpenBLAS/archive/v$OPENBLASVER.tar.gz
	tar xvzf v$OPENBLASVER.tar.gz
	cd OpenBLAS-$OPENBLASVER
	if [ "`uname -s`" = FreeBSD ]; then
		gmake $JFLAG DYNAMIC_ARCH=1 PREFIX=$SROOT USE_THREAD=1 libs netlib shared
		gmake install DYNAMIC_ARCH=1 PREFIX=$SROOT USE_THREAD=1
	else
		make $JFLAG DYNAMIC_ARCH=1 PREFIX=$SROOT USE_THREAD=1 libs netlib shared
		make install DYNAMIC_ARCH=1 PREFIX=$SROOT USE_THREAD=1
	fi
	ln -s $SROOT/lib/libopenblas.so $SROOT/lib/liblapack.so
	ln -s $SROOT/lib/libblas.so $SROOT/lib/libblas.so
fi

# SuiteSparse
if [ ! -f $SROOT/lib/libspqr.so ]; then
	cd $1
	FETCH https://github.com/DrTimothyAldenDavis/SuiteSparse/archive/v$SUITESPARSEVER.tar.gz
	tar xvzf v$SUITESPARSEVER.tar.gz
	cd SuiteSparse-$SUITESPARSEVER
	if [ "`uname -s`" = FreeBSD ]; then
		gmake $JFLAG library INSTALL=$SROOT
		gmake install INSTALL=$SROOT
	else
		make $JFLAG library INSTALL=$SROOT
		make install INSTALL=$SROOT
	fi
fi

# Freetype (needed for matplotlib, not always installed)
if [ ! -f $SROOT/lib/libfreetype.so ]; then
	cd $1
	FETCH http://download.savannah.gnu.org/releases/freetype/freetype-$FREETYPEVER.tar.bz2
	tar xvjf freetype-$FREETYPEVER.tar.bz2
	cd freetype-$FREETYPEVER
	./configure --prefix=$SROOT
	make $JFLAG
	make install
fi

# Gnuplot
if [ ! -f $SROOT/bin/gnuplot ]; then
	cd $1
	FETCH http://liquidtelecom.dl.sourceforge.net/project/gnuplot/gnuplot/$GNUPLOTVER/gnuplot-$GNUPLOTVER.tar.gz
	tar xvzf gnuplot-$GNUPLOTVER.tar.gz
	cd gnuplot-$GNUPLOTVER
	./configure --prefix=$SROOT --without-linux-vga --without-lisp-files --with-bitmap-terminals --without-latex
	make $JFLAG
	# Fix brokenness in build system with hard dependencies on optional files
	touch docs/gnuplot-eldoc.el docs/gnuplot-eldoc.elc
	make install
fi

# PGPLOT
if [ ! -f $SROOT/lib/libcpgplot.so ]; then
	# fetch
	cd $1
	FETCH ftp://ftp.astro.caltech.edu/pub/pgplot/pgplot$(echo $PGPLOTVER | cut -f 1,2 -d .).tar.gz
	tar xvzf pgplot$(echo $PGPLOTVER | cut -f 1,2 -d .).tar.gz
	patch -p0 < $SROOTBASE/tools/pgplot$PGPLOTVER.patch
	cd pgplot
	mkdir build
	cd build
	cp ../drivers.list .
	../makemake .. linux clustertools
	make
	make cpg
	install pgxwin_server $SROOT/bin
	install lib* $SROOT/lib
	install *.h $SROOT/include
	mkdir -p $SROOT/share/pgplot
	install grfont.dat rgb.txt $SROOT/share/pgplot
fi

# CFITSIO
if [ ! -f $SROOT/lib/libcfitsio.so ]; then
	cd $1
	FETCH http://heasarc.gsfc.nasa.gov/FTP/software/fitsio/c/cfitsio-$CFITSIOVER.tar.gz
	tar xvzf cfitsio-$CFITSIOVER.tar.gz
	cd cfitsio-$CFITSIOVER
	./configure --prefix=$SROOT --enable-bzip2=$SROOT
	make $JFLAG
	make $JFLAG shared
	make install
fi

# HDF5
if [ ! -f $SROOT/bin/h5ls ]; then
	cd $1
	FETCH http://www.hdfgroup.org/ftp/HDF5/releases/hdf5-$(echo $HDF5VER | cut -f 1,2 -d .)/hdf5-$HDF5VER/src/hdf5-$HDF5VER.tar.bz2
	tar xvjf hdf5-$HDF5VER.tar.bz2
	cd hdf5-$HDF5VER
	export HDF5_CC=$SROOT/bin/gcc
	./configure --prefix=$SROOT --enable-build-mode=production --enable-cxx --enable-strict-format-checks --with-zlib=/usr
	make $JFLAG
	make install
fi

# NetCDF
if [ ! -f $SROOT/bin/ncdump ]; then
	cd $1
	FETCH https://github.com/Unidata/netcdf-c/archive/v$NETCDFVER.tar.gz
	tar xvzf v$NETCDFVER.tar.gz
	cd netcdf-c-$NETCDFVER
	LDFLAGS=-L$SROOT/lib ./configure --prefix=$SROOT --disable-dap
	make $JFLAG
	make install
fi

if [ ! -f $SROOT/lib/libnetcdf_c++4.so ]; then
	cd $1
	FETCH ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-cxx4-$NETCDFCXXVER.tar.gz
	tar xvzf netcdf-cxx4-$NETCDFCXXVER.tar.gz
	cd netcdf-cxx4-$NETCDFCXXVER
	LDFLAGS=-L$SROOT/lib ./configure --prefix=$SROOT
	make $JFLAG
	make install
fi

# Dependencies for python stuff
export HDF5_DIR=$SROOT
export BLAS=$SROOT/lib/libopenblas.so
export LAPACK=$SROOT/lib/libopenblas.so
#export LDFLAGS="-L$SROOT/lib" # Needed for Darwin? add back later, breaks RHEL

# FFTW
if [ ! -f $SROOT/lib/libfftw3l.so ]; then
	cd $1
	FETCH http://www.fftw.org/fftw-$FFTWVER.tar.gz
	tar xvzf fftw-$FFTWVER.tar.gz
	cd fftw-$FFTWVER
	CC="$CC -mtune=generic" ./configure --prefix=$SROOT --enable-shared --enable-float --enable-threads
	make
	make install

	cd $1
	rm -rf fftw-$FFTWVER
	tar xvzf fftw-$FFTWVER.tar.gz
	cd fftw-$FFTWVER
	CC="$CC -mtune=generic" ./configure --prefix=$SROOT --enable-shared --enable-long-double --enable-threads
	make
	make install

	cd $1
	rm -rf fftw-$FFTWVER
	tar xvzf fftw-$FFTWVER.tar.gz
	cd fftw-$FFTWVER
	CC="$CC -mtune=generic" ./configure --prefix=$SROOT --enable-shared --enable-threads
	make
	make install
fi

# FLAC
if [ ! -f $SROOT/bin/flac ]; then
	cd $1
	FETCH http://downloads.xiph.org/releases/flac/flac-$FLACVER.tar.xz
	rm -f flac-$FLACVER.tar
	xz -d flac-$FLACVER.tar.xz
	tar xvf flac-$FLACVER.tar
	cd flac-$FLACVER
	./configure --prefix=$SROOT
	make
	make install
fi

# GSL
if [ ! -f $SROOT/lib/libgsl.so ]; then
	cd $1
	FETCH ftp://ftp.gnu.org/gnu/gsl/gsl-$GSLVER.tar.gz
	tar xvzf gsl-$GSLVER.tar.gz
	cd gsl-$GSLVER
	./configure --prefix=$SROOT
	make
	make install
fi

# HEALPIX
if [ ! -f $SROOT/lib/libhealpix.a ]; then
	HPXVER=$(echo $HEALPIXVER | cut -f 1 -d _)
	cd $1
	FETCH http://liquidtelecom.dl.sourceforge.net/project/healpix/Healpix_$HPXVER/Healpix_$HEALPIXVER.tar.gz
	tar xvzf Healpix_$HEALPIXVER.tar.gz
	cd Healpix_$HPXVER
	if ! grep -q AM_PROG_CC_C_O src/common_libraries/libsharp/configure.ac; then
	    SEDI "/AC_PROG_CC_C99/aAM_PROG_CC_C_O" src/common_libraries/libsharp/configure.ac
	fi
	./configure -L <<EOF
3
$CC

$FC


-I$SROOT/include -I\$(F90_INCDIR) -L$SROOT/lib

$CC
-O3 -std=c99 -I$SROOT/include -L$SROOT/lib


$SROOT/lib





0
EOF
	cd src/common_libraries/libsharp
	autoreconf -vifs
	./configure --prefix=$SROOT
	make
	make install
	cd -
 	cd src/cxx
 	autoreconf -vifs
 	CXXFLAGS=-I$SROOT/include CFLAGS=-I$SROOT/include LDFLAGS=-L$SROOT/lib ./configure --prefix=$SROOT
 	make
 	make install
 	cd -
 	cd src/C/autotools
 	autoreconf -vifs
 	CFLAGS=-I$SROOT/include LDFLAGS=-L$SROOT/lib ./configure --prefix=$SROOT
 	make
 	make install
 	cd -
	make
	install -m 755 bin/* $SROOT/bin
	mkdir -p $SROOT/include/healpix
	install -m 644 include/*.mod $SROOT/include/healpix
	install -m 644 lib/*.a $SROOT/lib
	SEDI "s#prefix=$PWD#prefix=$SROOT#" lib/pkgconfig/healpix.pc
	SEDI "s#includedir=\${prefix}/include#includedir=\${prefix}/include/healpix#" lib/pkgconfig/healpix.pc
	install -m 644 lib/pkgconfig/healpix.pc $SROOT/lib/pkgconfig
fi

# lenspix
if [ ! -f $SROOT/bin/simlens ]; then
	cd $1
	FETCH https://github.com/cmbant/lenspix/archive/$LENSPIXVER.zip
	unzip $LENSPIXVER.zip
	cd lenspix-$LENSPIXVER
	cp Makefile Makefile_clustertools
	cat > makefile.patch <<EOF
4c4
< F90C     = mpif90
---
> F90C     = gfortran
12c12
< FFLAGS = -O3 -xHost -ip -fpp -error-limit 500 -DMPIPIX -DMPI -heap-arrays
---
> FFLAGS = -O3 -cpp
18c18
< F90FLAGS = \$(FFLAGS) -I\$(INCLUDE) -I\$(healpix)/include -L\$(cfitsio)/lib -L\$(healpix)/lib \$(LAPACKL) -lcfitsio
---
> F90FLAGS = \$(FFLAGS) -I. -I\$(SROOT)/include/healpix -L\$(SROOT)/lib -lcfitsio -L\$(SROOT)/lib -lhealpix -lsharp -fopenmp
EOF
	patch Makefile_clustertools makefile.patch
	make -f Makefile_clustertools all
	install -m 755 recon simlens $SROOT/bin
fi

#PolSpice
if [ ! -f $SROOT/bin/spice ]; then
	cd $1
	FETCH ftp://ftp.iap.fr/pub/from_users/hivon/PolSpice/PolSpice_$SPICEVER.tar.gz
	tar xzvf PolSpice_$SPICEVER.tar.gz
	cd PolSpice_$SPICEVER
	mkdir build
	cd build
	cmake .. -DHEALPIX=$SROOT -DHEALPIX_INCLUDE=$SROOT/include/healpix -DSHARP_INCLUDES=$SROOT/include
	make
	install -m 755 spice $SROOT/bin
fi

# Python packages
pip install --cache-dir $1 -b $1 $PYTHON_PKGS_TO_INSTALL

# Globus
if [ ! -f $SROOT/bin/globus-url-copy -a ! -z "$GLOBUSVER" ]; then
	cd $1
	FETCH http://downloads.globus.org/toolkit/gt6/stable/installers/src/globus_toolkit-$GLOBUSVER.tar.gz
	tar xvzf globus_toolkit-$GLOBUSVER.tar.gz
	cd globus_toolkit-$GLOBUSVER
	./configure --prefix=$SROOT --enable-myproxy --disable-gsi-openssh --disable-gram5 --enable-shared=no
	make 
	make install
fi

# GFAL
if [ ! -f $SROOT/bin/gfal-copy -a ! -z "$GFALVER" ]; then
	cd $1
	FETCH https://gitlab.cern.ch/dmc/gfal2/-/archive/v$GFALVER/gfal2-v$GFALVER.tar.gz
	tar xvzf gfal2-v$GFALVER.tar.gz
	cd gfal2-v$GFALVER
	mkdir build
	cd build
	cmake .. -DCMAKE_INSTALL_PREFIX=$SROOT
	make 
	make install
fi

set +e
rm -rf $1
trap true EXIT
echo Build and installation successful

