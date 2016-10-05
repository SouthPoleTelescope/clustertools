#!/bin/sh

# Usage: bootstrap_platform_tools.sh scratchdir

JFLAG=-j8

# Versions and tools
GCCVER=5.3.0
BINUTILSVER=2.26
MPCVER=1.0.3
MPFRVER=3.1.5
GMPVER=6.1.0

PYVER=2.7.11
PYSETUPTOOLSVER=24.0.3
PIPVER=8.1.2
BOOSTVER=1.57.0
HDF5VER=1.8.17
NETCDFVER=4.4.0
FFTWVER=3.3.4
GSLVER=2.1

GNUPLOTVER=4.6.3
TCLVER=8.6.5
BZIPVER=1.0.6
ZLIBVER=1.2.8 # NB: built conditionally
XZVER=5.2.2
CMAKEVER=3.5.2
FLACVER=1.3.1
FREETYPEVER=2.6.3
CFITSIOVER=3.390
OPENBLASVER=0.2.18

PYTHON_PKGS_TO_INSTALL="numpy==1.11.1 scipy==0.16.1 readline==6.2.4.1 ipython==5.0.0 jupyter==1.0.0 pyfits==3.0.7 astropy==1.1.2 numexpr==2.5.2 Cython==0.24 matplotlib==1.5.0 Sphinx==1.4.1 tables==3.2.3.1 urwid==1.3.1 pyFFTW==0.10.1 healpy==1.9.1 spectrum==0.6.1 tornado==4.3 SQLAlchemy==1.0.13 PyYAML==3.11 ephem==3.7.6.0 idlsave==1.0.0 ipdb==0.10.0 pyzmq==15.2.0 jsonschema==2.5.1 h5py==2.6.0"

# Extra things for grid tools
#GLOBUSVER=5.2.4
#PYTHON_PKGS_TO_INSTALL="$PYTHON_PKGS_TO_INSTALL pyOpenSSL==0.13 pyasn1==0.1.7 jsonrpclib==0.1.3 configobj==4.7.2 coverage==3.6 flexmock==0.9.7 pyuv==0.10.4"

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

set -e 
trap "echo Build Error" EXIT

mkdir -p $SROOT
mkdir -p $1

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
	FETCH http://www.mpfr.org/mpfr-current/mpfr-$MPFRVER.tar.gz
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
	./configure --prefix=$SROOT --with-gmp-include=$SROOT/include --with-gmp-lib=$SROOT/lib
	make $JFLAG; make install

	cd $1
	FETCH http://www.netgull.com/gcc/releases/gcc-$GCCVER/gcc-$GCCVER.tar.gz
	tar xvzf gcc-$GCCVER.tar.gz
	cd gcc-$GCCVER
	# Subshell here prevents some kind of space madness on RHEL6
	(LD=`which ld` AS=`which as` LD_FOR_TARGET=`which ld` ./configure --prefix=$SROOT --with-gmp=$SROOT --disable-multilib --enable-languages=c,c++,fortran)
	make $JFLAG; make install

	export CC=$SROOT/bin/gcc
	export CXX=$SROOT/bin/g++
	export FC=$SROOT/bin/gfortran
fi

# Bzip2
if [ ! -f $SROOT/bin/bzip2 ]; then
	cd $1
	FETCH http://www.bzip.org/$BZIPVER/bzip2-$BZIPVER.tar.gz
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

# XZ
if [ ! -f $SROOT/bin/xz ]; then
	cd $1
	FETCH http://tukaani.org/xz/xz-$XZVER.tar.gz
	tar xvzf xz-$XZVER.tar.gz
	cd xz-$XZVER
	./configure --prefix=$SROOT --enable-shared
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

# Python
if [ ! -f $SROOT/bin/python ]; then
	cd $1
	FETCH http://www.python.org/ftp/python/$PYVER/Python-$PYVER.tgz
	tar xvzf Python-$PYVER.tgz
	cd Python-$PYVER
	./configure --prefix=$SROOT --enable-shared
	make $JFLAG
	make install
fi

# Python Setuptools
if python -c 'import setuptools'; then
	true
else
	cd $1
	FETCH https://pypi.python.org/packages/84/24/610d8bb87219ed6d0928018b7b35ac6f6f6ef27a71ed6a2d0cfb68200f65/setuptools-$PYSETUPTOOLSVER.tar.gz
	tar xvzf setuptools-$PYSETUPTOOLSVER.tar.gz
	cd setuptools-$PYSETUPTOOLSVER
	python setup.py build
	python setup.py install --prefix=$SROOT
fi

# Pip
if [ ! -f $SROOT/bin/pip ]; then
	cd $1
	FETCH http://pypi.python.org/packages/e7/a8/7556133689add8d1a54c0b14aeff0acb03c64707ce100ecd53934da1aa13/pip-$PIPVER.tar.gz
	tar xvzf pip-$PIPVER.tar.gz
	cd pip-$PIPVER
	python setup.py build
	python setup.py install --prefix=$SROOT
fi

# Boost
if [ ! -f $SROOT/lib/libboost_python.so ]; then
	cd $1
	tarball=boost_`echo $BOOSTVER | tr . _`
	FETCH http://liquidtelecom.dl.sourceforge.net/project/boost/boost/$BOOSTVER/$tarball.tar.bz2
	tar xvjf $tarball.tar.bz2
	cd $tarball
	./bootstrap.sh --prefix=$SROOT --with-python=$SROOT/bin/python --with-python-root=$SROOT
	./b2 $JFLAG
	./b2 install
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
if [ ! -f $SROOT/lib/libopenblas.so ]; then
	cd $1
	FETCH http://github.com/xianyi/OpenBLAS/archive/v$OPENBLASVER
	tar xvzf v$OPENBLASVER
	cd OpenBLAS-$OPENBLASVER
	make $JFLAG DYNAMIC_ARCH=1 PREFIX=$SROOT USE_THREAD=1
	make install DYNAMIC_ARCH=1 PREFIX=$SROOT USE_THREAD=1
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
	./configure --prefix=$SROOT --without-linux-vga --without-lisp-files --with-bitmap-terminals
	make $JFLAG
	# Fix brokenness in build system with hard dependencies on optional files
	touch docs/gnuplot-eldoc.el docs/gnuplot-eldoc.elc
	make install
fi

# CFITSIO
if [ ! -f $SROOT/lib/libcfitsio.so ]; then
	cd $1
	FETCH http://heasarc.gsfc.nasa.gov/FTP/software/fitsio/c/cfitsio$(echo $CFITSIOVER | tr -d .).tar.gz
	tar xvzf cfitsio$(echo $CFITSIOVER | tr -d .).tar.gz
	cd cfitsio
	./configure --prefix=$SROOT --enable-bzip2=$SROOT
	make $JFLAG
	make $JFLAG shared
	make install
fi

# HDF5
if [ ! -f $SROOT/bin/h5ls ]; then
	cd $1
	FETCH http://www.hdfgroup.org/ftp/HDF5/releases/hdf5-$HDF5VER/src/hdf5-$HDF5VER.tar.bz2
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
	FETCH ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-$NETCDFVER.tar.gz
	tar xvzf netcdf-$NETCDFVER.tar.gz
	cd netcdf-$NETCDFVER
	./configure --prefix=$SROOT
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

# Python packages
for pkg in $PYTHON_PKGS_TO_INSTALL; do
	case $pkg in
	pyFFTW*)
		CFLAGS="-I $SROOT/include"  pip install -b $1 pyFFTW
		;;
	#healpy*)
	#	pip install -b $1 --global-option --without-native $pkg
	#	;;
	*)
		pip install -b $1 $pkg
		;;
	esac
done

# Globus
if [ ! -f $SROOT/bin/globus-url-copy -a ! -z "$GLOBUSVER" ]; then
	cd $1
	FETCH http://www.globus.org/ftppub/gt5/`echo $GLOBUSVER | cut -f 1,2 -d .`/$GLOBUSVER/installers/src/gt$GLOBUSVER-all-source-installer.tar.gz
	tar xvzf gt$GLOBUSVER-all-source-installer.tar.gz
	cd gt$GLOBUSVER-all-source-installer
	./configure --prefix=$SROOT
	make gpt globus-data-management-client
	make install
fi

set +e
rm -rf $1
trap true EXIT
echo Build and installation successful

