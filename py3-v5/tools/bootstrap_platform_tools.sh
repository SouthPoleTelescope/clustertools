#!/bin/sh

# Usage: bootstrap_platform_tools.sh scratchdir

JFLAGN=8
JFLAG=-j$JFLAGN

# Versions and tools
GCCVER=13.2.0
BINUTILSVER=2.42
MPCVER=1.3.1
MPFRVER=4.2.1
GMPVER=6.3.0

SQLITEVER=3450300
OPENSSLVER=3.0.13
PYVER=3.12.3
BOOSTVER=1.85.0
HDF5VER=1.14.3
NETCDFVER=4.9.2
NETCDFCXXVER=4.3.1
FFTWVER=3.3.10
GSLVER=2.7

GNUPLOTVER=6.0.0
PGPLOTVER=5.2.2
TCLVER=8.6.14
BZIPVER=1.0.8
ZLIBVER=1.3.1 # NB: built conditionally
CMAKEVER=3.29.2
FLACVER=1.4.3
FREETYPEVER=2.13.2
CFITSIOVER=4.4.0
OPENBLASVER=0.3.27
SUITESPARSEVER=7.7.0

HEALPIXVER=3.82_2022Jul28
LENSPIXVER=3c76223024f91f693e422ae89cb1cf2e81e061da
SPICEVER=v03-08-01
JULIAVER=1.10.2

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
	FETCH http://gmplib.org/download/gmp/gmp-$GMPVER.tar.gz
	tar xzvf gmp-$GMPVER.tar.gz
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
	FETCH https://sourceware.org/pub/bzip2/bzip2-$BZIPVER.tar.gz
	tar xvzf bzip2-$BZIPVER.tar.gz
	cd bzip2-$BZIPVER
	make install PREFIX=$SROOT
	make clean
	make -f Makefile-libbz2_so PREFIX=$SROOT
	cp libbz2.so.$BZIPVER libbz2.so.1.0 $SROOT/lib
	cd $SROOT/lib
	ln -sf libbz2.so.1.0 libbz2.so
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

if [ ! -f $SROOT/bin/sqlite3 ]; then
	cd $1
	FETCH https://www.sqlite.org/2024/sqlite-autoconf-$SQLITEVER.tar.gz
	tar xvzf sqlite-autoconf-$SQLITEVER.tar.gz
	cd sqlite-autoconf-$SQLITEVER
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
	./configure --prefix=$SROOT
	make $JFLAG
	make install install-libraries
	cd $1
	cd tk$TCLVER/unix
	# TK is an optional dependency
	./configure --prefix=$SROOT
	make $JFLAG
	make install
	cd $SROOT/bin
	ln -sf tclsh8.6 tclsh
fi

# Python 3.10+ requires OpenSSL >= 1.1, which certain
# ancient OSes (RHEL7) don't have. That seems to be the only one we
# care about, so use a lazy test.
# yum install perl-IPC-Cmd
# yum install curl-devel
if (echo $OS_ARCH | grep -q RHEL_7); then
	rm -rf $SROOT/lib/gcc/x86_64-pc-linux-gnu/$GCCVER/include-fixed/openssl
	if [ ! -r $SROOT/lib/libcrypto.so ]; then
		cd $1
		FETCH https://www.openssl.org/source/openssl-$OPENSSLVER.tar.gz
		tar xvzf openssl-$OPENSSLVER.tar.gz
		cd openssl-$OPENSSLVER
		./config --prefix=$SROOT
		make $JFLAG
		make install
	fi
fi

# yum install libuuid-devel

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
	ln -sf python3 python
	ln -sf python3-config python-config
	ln -sf pip3 pip
	cd $SROOT/lib
	ln -sf pkgconfig/python3.pc pkgconfig/python.pc
	cd $SROOT/include
	ln -sf python${PYSHORTVER}m python${PYSHORTVER}
	if [ $(uname -s) == Darwin ]; then
		cd $SROOT/lib
		ln -sf libpython${PYSHORTVER}m.dylib libpython${PYSHORTVER}.dylib
	fi
fi

# Boost
if [ ! -r $SROOT/lib/libboost_python.so ]; then
	cd $1
	tarball=boost_`echo $BOOSTVER | tr . _`
	FETCH https://boostorg.jfrog.io/artifactory/main/release/$BOOSTVER/source/$tarball.tar.bz2
	tar xvjf $tarball.tar.bz2
	cd $tarball
	./bootstrap.sh --prefix=$SROOT --with-python=$SROOT/bin/python --with-python-root=$SROOT
	./b2 $JFLAG
	./b2 install

	cd $SROOT/lib
	PYSHORTVER=`echo $PYVER | cut -d . -f 1,2 | tr -d .`
	ln -sf libboost_python$PYSHORTVER.so libboost_python3.so
	ln -sf libboost_python3.so libboost_python.so
fi

# CMake
if [ ! -f $SROOT/bin/cmake ]; then
	cd $1
	FETCH http://github.com/Kitware/CMake/releases/download/v$CMAKEVER/cmake-$CMAKEVER.tar.gz
	tar xvzf cmake-$CMAKEVER.tar.gz
	cd cmake-$CMAKEVER
	./configure --prefix=$SROOT
	make $JFLAG; make install
fi

# OpenBLAS
if [ ! -h $SROOT/lib/libblas.so ]; then
	cd $1
	FETCH http://github.com/OpenMathLib/OpenBLAS/releases/download/v$OPENBLASVER/OpenBLAS-$OPENBLASVER.tar.gz
	tar xvzf OpenBLAS-$OPENBLASVER.tar.gz
	cd OpenBLAS-$OPENBLASVER
	if [ "`uname -s`" = FreeBSD ]; then
		gmake $JFLAG DYNAMIC_ARCH=1 PREFIX=$SROOT USE_THREAD=1 libs netlib shared
		gmake install DYNAMIC_ARCH=1 PREFIX=$SROOT USE_THREAD=1
	else
		make $JFLAG DYNAMIC_ARCH=1 PREFIX=$SROOT USE_THREAD=1 libs netlib shared
		make install DYNAMIC_ARCH=1 PREFIX=$SROOT USE_THREAD=1
	fi
	cd $SROOT/lib
	ln -sf libopenblas.so liblapack.so
	ln -sf libopenblas.so libblas.so
fi

# SuiteSparse
if [ ! -f $SROOT/lib/libspqr.so ]; then
	cd $1
	FETCH https://github.com/DrTimothyAldenDavis/SuiteSparse/archive/refs/tags/v$SUITESPARSEVER.tar.gz
	tar xvzf v$SUITESPARSEVER.tar.gz
	cd SuiteSparse-$SUITESPARSEVER
	mkdir -p build
	cd build
	cmake -DCMAKE_INSTALL_PREFIX=$SROOT ..
	cmake --build . --parallel $JFLAGN
	cmake --install .
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
	./configure --prefix=$SROOT --without-linux-vga --without-lisp-files --with-bitmap-terminals --without-latex --with-qt=no
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
	FETCH https://heasarc.gsfc.nasa.gov/FTP/software/fitsio/c/cfitsio-$CFITSIOVER.tar.gz
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
	LDFLAGS=-L$SROOT/lib ./configure --prefix=$SROOT --disable-dap --disable-libxml2
	make $JFLAG
	make install
fi

if [ ! -f $SROOT/lib/libnetcdf_c++4.so ]; then
	cd $1
	FETCH https://downloads.unidata.ucar.edu/netcdf-cxx/$NETCDFCXXVER/netcdf-cxx4-$NETCDFCXXVER.tar.gz
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
	CC="$CC -mtune=generic" ./configure --prefix=$SROOT --enable-shared --enable-float --enable-threads --enable-openmp
	make
	make install

	cd $1
	rm -rf fftw-$FFTWVER
	tar xvzf fftw-$FFTWVER.tar.gz
	cd fftw-$FFTWVER
	CC="$CC -mtune=generic" ./configure --prefix=$SROOT --enable-shared --enable-long-double --enable-threads --enable-openmp
	make
	make install

	cd $1
	rm -rf fftw-$FFTWVER
	tar xvzf fftw-$FFTWVER.tar.gz
	cd fftw-$FFTWVER
	CC="$CC -mtune=generic" ./configure --prefix=$SROOT --enable-shared --enable-threads --enable-openmp
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
	rm -rf Healpix-$HPXVER
	tar xvzf Healpix_$HEALPIXVER.tar.gz
	cd Healpix_$HPXVER
	./configure -L <<EOF
3
$CC


$FC


-I$SROOT/include -I\$(F90_INCDIR) -L$SROOT/lib -fallow-argument-mismatch -fPIC

$CC
-O3 -std=c99 -fPIC -I$SROOT/include -L$SROOT/lib -I\$(HEALPIX)/include


$SROOT/lib





0
EOF
	cd src/common_libraries/libsharp
	./configure --prefix=$SROOT --with-pic
	make
	make install
	cd -
 	cd src/cxx
 	CXXFLAGS=-I$SROOT/include CFLAGS=-I$SROOT/include LDFLAGS=-L$SROOT/lib ./configure --prefix=$SROOT --with-pic
 	make
 	make install
 	cd -
 	cd src/C/autotools
 	autoreconf -vifs
 	CFLAGS=-I$SROOT/include LDFLAGS=-L$SROOT/lib ./configure --prefix=$SROOT --with-pic
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
	mkdir -p $SROOT/share/healpix
	install -m 644 data/* $SROOT/share/healpix
fi

# lenspix
# yum install zip
# yum install unzip
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

# PolSpice
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
TMP=$1 pip install --cache-dir $1 --no-clean -r $SROOTBASE/tools/requirements.txt

# Gfal tools
if [ ! -f $SROOT/bin/gfal-cat ]; then
	for tool in gfal-cat gfal-chmod gfal-copy gfal-ls gfal-mkdir gfal-rename gfal-rm gfal-save gfal-stat gfal-sum gfal-xattr; do
		ln -sf $SROOTBASE/gfal_run.sh $SROOT/bin/$tool
	done
fi

# NaMaster
if [ ! -f $SROOT/lib/python3.12/site-packages/pymaster/__init__.py ]; then
	cd $1
	FETCH https://github.com/LSSTDESC/NaMaster/archive/refs/tags/v$NMTVER.tar.gz
	tar xzvf v$NMTVER.tar.gz
	cd NaMaster-$NMTVER
	mkdir -p _deps/lib
	ln -sf $SROOT/lib/libchealpix.a _deps/lib/libchealpix.a
	mkdir -p _deps/include
	[ -e _deps/libsharp2 ] || git clone https://gitlab.mpcdf.mpg.de/mtr/libsharp.git _deps/libsharp2
	echo AM_PROG_CC_C_O >> _deps/libsharp2/configure.ac
	pip install .
fi

# Julia
if [ ! -f $SROOT/bin/julia ]; then
	JVER=$(echo $JULIAVER | cut -f 1,2 -d .)
	cd $1
	FETCH https://julialang-s3.julialang.org/bin/linux/x64/$JVER/julia-$JULIAVER-linux-x86_64.tar.gz
	mkdir -p $SROOT/opt
	cd $SROOT/opt
	tar xzvf $1/julia-$JULIAVER-linux-x86_64.tar.gz
	cd $SROOT/bin
	ln -sf ../opt/julia-$JULIAVER/bin/julia julia
fi

set +e
# rm -rf $1
trap true EXIT
echo Build and installation successful

