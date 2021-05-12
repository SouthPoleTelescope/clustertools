#!/bin/sh

# Usage: bootstrap_platform_tools.sh scratchdir

JFLAG=-j8

# Versions and tools
GCCVER=10.2.0
BINUTILSVER=2.35
MPCVER=1.2.0
MPFRVER=4.1.0
GMPVER=6.2.0

SQLITEVER=3330000
PYVER=3.8.5
PYSETUPTOOLSVER=49.6.0
PIPVER=20.2.2
BOOSTVER=1.73.0
HDF5VER=1.12.0
NETCDFVER=4.7.4
NETCDFCXXVER=4.3.1
FFTWVER=3.3.8
GSLVER=2.6

GNUPLOTVER=5.2.8
PGPLOTVER=5.2.2
TCLVER=8.6.10
BZIPVER=1.0.8
ZLIBVER=1.2.11 # NB: built conditionally
CMAKEVER=3.18.2
FLACVER=1.3.3
FREETYPEVER=2.10.2
CFITSIOVER=3.49
OPENBLASVER=0.3.10
SUITESPARSEVER=5.8.1

HEALPIXVER=3.70_2020Jul23
LENSPIXVER=3c76223024f91f693e422ae89cb1cf2e81e061da
SPICEVER=v03-07-02

# Below is a frozen version of (order is important in some cases) as of 8/22/20:
PYTHON_PKGS_TO_INSTALL="wheel==0.35.1 rst2html5==1.10.6 numpy==1.19.1 scipy==1.5.2 tornado==6.0.4 ipython==7.17.0 pyfits==3.5 numexpr==2.7.1 matplotlib==3.3.1 xhtml2pdf==0.2.4 Sphinx==3.2.1 tables==3.6.1 urwid==2.1.1 pyFFTW==0.12.0 spectrum==0.7.6 SQLAlchemy==1.3.19 PyYAML==5.3.1 ephem==3.7.7.1 idlsave==1.0.0 ipdb==0.13.3 jsonschema==3.2.0 memory_profiler==0.57.0 simplejson==3.17.2 joblib==0.16.0 lmfit==1.0.1 camb==1.1.3 h5py==2.10.0 pandas==1.1.1 astropy==4.0.1.post1 healpy==1.14.0 jupyter==1.0.0 pytest==6.0.1 astroquery==0.4.1 snakemake==6.3.0"

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
cd $SROOT
ln -sf lib lib64

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
	FETCH https://ftp.gnu.org/gnu/mpc/mpc-$MPCVER.tar.gz
	tar xvzf mpc-$MPCVER.tar.gz
	cd mpc-$MPCVER
	./configure --prefix=$SROOT --with-gmp-include=$SROOT/include --with-gmp-lib=$SROOT/lib
	make $JFLAG; make install

	cd $1
	FETCH https://ftp.gnu.org/gnu/binutils/binutils-$BINUTILSVER.tar.gz
	tar xvzf binutils-$BINUTILSVER.tar.gz
	cd binutils-$BINUTILSVER
	./configure --prefix=$SROOT --disable-gprof --with-gmp-include=$SROOT/include --with-gmp-lib=$SROOT/lib
	make $JFLAG; make install

	cd $1
	FETCH https://ftp.gnu.org/gnu/gcc/gcc-$GCCVER/gcc-$GCCVER.tar.gz
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
	cp libbz2.so.$BZIPVER libbz2.so.1.0 $SROOT/lib
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
	FETCH https://prdownloads.sourceforge.net/tcl/tcl$TCLVER-src.tar.gz
	FETCH https://prdownloads.sourceforge.net/tcl/tk$TCLVER-src.tar.gz
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
	cd $SROOT/bin
	ln -s tclsh8.6 tclsh
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

if [ ! -f $SROOT/bin/sqlite3 ]; then
	cd $1
	FETCH https://www.sqlite.org/2020/sqlite-autoconf-$SQLITEVER.tar.gz
	tar xvzf sqlite-autoconf-$SQLITEVER.tar.gz
	cd sqlite-autoconf-$SQLITEVER
	./configure --prefix=$SROOT
	make $JFLAG
	make install
fi

# Python build finished successfully!
# The necessary bits to build these optional modules were not found:
# _curses               _curses_panel         _dbm
# _gdbm                 _lzma                 _uuid
# readline
# To find the necessary bits, look in setup.py in detect_modules() for the module's name.

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
	cd $SROOT/bin
	ln -s python3 python
	ln -s python3-config python-config
	cd $SROOT/lib
	ln -s pkgconfig/python3.pc pkgconfig/python.pc
	cd $SROOT/include
	ln -s python${PYSHORTVER}m python${PYSHORTVER}
	if [ $(uname -s) == Darwin ]; then
		cd $SROOT/lib
		ln -s libpython${PYSHORTVER}m.dylib libpython${PYSHORTVER}.dylib
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
	FETCH https://dl.bintray.com/boostorg/release/$BOOSTVER/source/$tarball.tar.bz2
	tar xvjf $tarball.tar.bz2
	cd $tarball
	./bootstrap.sh --prefix=$SROOT --with-python=$SROOT/bin/python --with-python-root=$SROOT
	./b2 $JFLAG
	./b2 install

	cd $SROOT/lib
	PYSHORTVER=`echo $PYVER | cut -d . -f 1,2 | tr -d .`
	ln -s libboost_python$PYSHORTVER.so libboost_python3.so
	ln -s libboost_python3.so libboost_python.so
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
	cd $SROOT/lib
	ln -s libopenblas.so liblapack.so
	ln -s libopenblas.so libblas.so
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
	FETCH http://download.savannah.gnu.org/releases/freetype/freetype-$FREETYPEVER.tar.gz
	tar xvzf freetype-$FREETYPEVER.tar.gz
	cd freetype-$FREETYPEVER
	./configure --prefix=$SROOT
	make $JFLAG
	make install
fi

# Gnuplot
if [ ! -f $SROOT/bin/gnuplot ]; then
	cd $1
	FETCH https://prdownloads.sourceforge.net/gnuplot/gnuplot/$GNUPLOTVER/gnuplot-$GNUPLOTVER.tar.gz
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
	FETCH https://prdownloads.sourceforge.net/healpix/Healpix_$HPXVER/Healpix_$HEALPIXVER.tar.gz
	tar xvzf Healpix_$HEALPIXVER.tar.gz
	cd Healpix_$HPXVER
	./configure -L <<EOF
3
$CC

$FC


-I$SROOT/include -I\$(F90_INCDIR) -L$SROOT/lib -fallow-argument-mismatch

$CC
-O3 -std=c99 -I$SROOT/include -L$SROOT/lib -I\$(HEALPIX)/include


$SROOT/lib





0
EOF
	cd src/common_libraries/libsharp
	./configure --prefix=$SROOT
	make
	make install
	cd -
 	cd src/cxx
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
	FETCH http://www2.iap.fr/users/hivon/software/PolSpice/ftp/PolSpice_$SPICEVER.tar.gz
	tar xzvf PolSpice_$SPICEVER.tar.gz
	cd PolSpice_$SPICEVER
	mkdir build
	cd build
	cmake .. -DHEALPIX=$SROOT -DHEALPIX_INCLUDE=$SROOT/include/healpix -DSHARP_INCLUDES=$SROOT/include
	make
	install -m 755 spice $SROOT/bin
fi

# Python packages
# one at a time to make sure dependencies are installed in order
for pkg in $PYTHON_PKGS_TO_INSTALL; do
	TMP=$1 pip install --cache-dir $1 --no-clean $pkg
done

# Gfal tools
if [ ! -f $SROOT/bin/gfal-cat ]; then
	for tool in gfal-cat gfal-chmod gfal-copy gfal-ls gfal-mkdir gfal-rename gfal-rm gfal-save gfal-stat gfal-sum gfal-xattr; do
		ln -s $SROOTBASE/gfal_run.sh $SROOT/bin/$tool
	done
fi

set +e
rm -rf $1
trap true EXIT
echo Build and installation successful

