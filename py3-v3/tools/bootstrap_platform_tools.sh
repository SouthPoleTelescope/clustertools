#!/bin/sh

# Usage: bootstrap_platform_tools.sh scratchdir

JFLAG=-j8

# Versions and tools
GCCVER=8.2.0
BINUTILSVER=2.30
MPCVER=1.1.0
MPFRVER=4.0.1
GMPVER=6.1.2

PYVER=3.7.0
PYSETUPTOOLSVER=39.2.0
PIPVER=18.0
BOOSTVER=1.68.0
HDF5VER=1.10.1
NETCDFVER=4.6.1
NETCDFCXXVER=4.3.0
FFTWVER=3.3.8
GSLVER=2.5

GNUPLOTVER=5.0.6
PGPLOTVER=5.2.2
TCLVER=8.6.8
BZIPVER=1.0.6
ZLIBVER=1.2.11 # NB: built conditionally
CMAKEVER=3.12.0
FLACVER=1.3.2
FREETYPEVER=2.9.1
CFITSIOVER=3.450
OPENBLASVER=0.2.20

HEALPIXVER=3.40_2018Jun22
CAMBVER=0.1.7
LENSPIXVER=3c76223024f91f693e422ae89cb1cf2e81e061da
SPICEVER=v03-05-01

PYTHON_PKGS_TO_INSTALL="wheel==0.31.1 numpy==1.15.0 scipy==1.1.0 ipython==6.5.0 jupyter==1.0.0 pyfits==3.5 astropy==3.0.4 numexpr==2.6.6 Cython==0.28.5 matplotlib==2.2.3 Sphinx==1.7.6 tables==3.4.4 urwid==2.0.1 pyFFTW==0.10.4 healpy==1.12.4 spectrum==0.7.3 tornado==5.1 SQLAlchemy==1.2.10 PyYAML==3.13 ephem==3.7.6.0 idlsave==1.0.0 ipdb==0.11 jsonschema==2.6.0 h5py==2.8.0 pandas==0.23.4 memory_profiler==0.54.0 simplejson==3.16.0 joblib==0.12.2 lmfit==0.9.11 camb==$CAMBVER" # line_profiler==2.1.2

# Extra things for grid tools
GLOBUSVER=6.0.1493989444

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
		sed -i $1 $2
	}
elif sed -e 's/test/TEST/g' -i '' $TESTFILE; then
	SEDI () {
		sed -e $1 -i '' $2
	}
else
	echo "Cannot figure out how to replace text!"
	exit 1
fi

exit

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
if [ ! -f $SROOT/lib/libboost_python.so ]; then
	cd $1
	tarball=boost_`echo $BOOSTVER | tr . _`
	FETCH http://liquidtelecom.dl.sourceforge.net/project/boost/boost/$BOOSTVER/$tarball.tar.bz2
	tar xvjf $tarball.tar.bz2
	cd $tarball
	./bootstrap.sh --prefix=$SROOT --with-python=$SROOT/bin/python --with-python-root=$SROOT
	./b2 $JFLAG
	./b2 install

	ln -s $SROOT/lib/libboost_python37.so $SROOT/lib/libboost_python3.so
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
if [ ! -f $SROOT/lib/libopenblas.so ]; then
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
	FETCH ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-$NETCDFVER.tar.gz
	tar xvzf netcdf-$NETCDFVER.tar.gz
	cd netcdf-$NETCDFVER
	./configure --prefix=$SROOT --disable-dap
	make $JFLAG
	make install
fi

if [ ! -f $SROOT/lib/libnetcdf_c++4.so ]; then
	cd $1
	FETCH ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-cxx4-$NETCDFCXXVER.tar.gz
	tar xvzf netcdf-cxx4-$NETCDFCXXVER.tar.gz
	cd netcdf-cxx4-$NETCDFCXXVER
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

# HEALPIX
if [ ! -f $SROOT/lib/libhealpix.a ]; then
    HPXVER=$(echo $HEALPIXVER | cut -f 1 -d _)
    cd $1
    FETCH http://liquidtelecom.dl.sourceforge.net/project/healpix/Healpix_$HPXVER/Healpix_$HEALPIXVER.tar.gz
    tar xvzf Healpix_$HEALPIXVER.tar.gz
    cd Healpix_$HPXVER
    cd src/cxx/autotools
    autoreconf -vifs
    ./configure --prefix=$SROOT
    make
    make install
    cd -
    cd src/C/autotools
    autoreconf -vifs
    ./configure --prefix=$SROOT
    make
    make install
    cd -
    ./configure <<EOF
3
$FC







$SROOT/lib





0
EOF
    make
    install -m 755 bin/* $SROOT/bin
    mkdir -p $SROOT/include/healpix
    install -m 644 include/* $SROOT/include/healpix
    install -m 644 lib/*.a $SROOT/lib
    SEDI "s#prefix=$PWD#prefix=$SROOT#" lib/healpix.pc
    SEDI "s#includedir=\${prefix}/include#includedir=\${prefix}/include/healpix#" lib/healpix.pc
    install -m 644 lib/healpix.pc $SROOT/lib/pkgconfig
fi

# CAMB
if [ ! -f $SROOT/lib/libcamb_recfast.a ]; then
    cd $1
    FETCH https://github.com/cmbant/CAMB/archive/$CAMBVER.tar.gz
    mv $CAMBVER.tar.gz camb-$CAMBVER.tar.gz
    tar xvzf camb-$CAMBVER.tar.gz
    cd CAMB-0.1.7
    SEDI "s#\$(HEALPIXDIR)/include#\$(HEALPIXDIR)/include/healpix#" Makefile_main
    make all COMPILER=gfortran HEALPIXDIR=$SROOT FITSDIR=$SROOT/lib
    make camb_fits COMPILER=gfortran HEALPIXDIR=$SROOT FITSDIR=$SROOT/lib
    install -m 644 Release/libcamb_recfast.a $SROOT/lib
    install camb camb_fits $SROOT/bin
fi

# lenspix
if [ ! -f $SROOT/bin/simlens ]; then
    cd $1
    FETCH https://github.com/cmbant/lenspix/archive/$LENSPIXVER.zip
    mv $LENSPIXVER.zip lenspix-$LENSPIXVER.zip
    rm -rf lenspix-$LENSPIXVER
    unzip lenspix-$LENSPIXVER.zip
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
> F90FLAGS = \$(FFLAGS) -I. -I\$(SROOT)/include/healpix -L\$(SROOT)/lib -lcfitsio -L\$(SROOT)/lib -lhealpix -fopenmp
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
    cd src
    cp Makefile_template Makefile
    SEDI "s#FC =#FC = $FC#" Makefile
    SEDI "s#FCFLAGS =#FCFLAGS = -fopenmp -O3#" Makefile
    SEDI "s#FITSLIB =#FITSLIB = $SROOT/lib#" Makefile
    SEDI "s#HPXINC = \$(HEALPIX)/include\$(SUFF)#HPXINC = $SROOT/include/healpix#" Makefile
    SEDI "s#HPXLIB = \$(HEALPIX)/lib\$(SUFF)#HPXLIB = $SROOT/lib#" Makefile
    make
    cd -
    install -m 755 bin/spice $SROOT/bin
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
	FETCH http://downloads.globus.org/toolkit/gt6/stable/installers/src/globus_toolkit-$GLOBUSVER.tar.gz
	tar xvzf globus_toolkit-$GLOBUSVER.tar.gz
	cd globus_toolkit-$GLOBUSVER
	./configure --prefix=$SROOT --enable-myproxy --disable-gsi-openssh --disable-gram5 --enable-shared=no
	make 
	make install
fi

set +e
rm -rf $1
trap true EXIT
echo Build and installation successful

