#!/bin/sh

# from bash or tcsh, call this script as:
# eval `/cvmfs/icecube.opensciencegrid.org/setup.sh`

# This is here since readlink -f doesn't work on Darwin
DIR=$(echo "${0%/*}")
SROOTBASE=$(cd "$DIR" && echo "$(pwd -L)")

. $SROOTBASE/os_arch.sh

SROOT=$SROOTBASE/$OS_ARCH
SITE_CMAKE_DIR=$SROOTBASE/site_cmake

if [ ! -d $SROOT ]; then
	echo "WARNING: The requested toolset ($SROOTBASE) has not yet been installed for this platform ($OS_ARCH). Please run (or have your admin run) \$SROOTBASE/tools/bootstrap_platform_tools.sh." >&2
fi

CC=$SROOT/bin/gcc
CXX=$SROOT/bin/g++
FC=$SROOT/bin/gfortran

PATH=$SROOT/bin:$PATH

PKG_CONFIG_PATH=$SROOT/lib/pkgconfig:$PKG_CONFIG_PATH
LD_LIBRARY_PATH=$SROOT/lib:$SROOT/lib64:$LD_LIBRARY_PATH
PYTHONPATH=$SROOT/lib/python3.10/site-packages:$PYTHONPATH
MANPATH=$SROOT/man:$SROOT/share/man:$MANPATH
CMAKE_PREFIX_PATH=$SROOT:$CMAKE_PREFIX_PATH
CMAKE_BIN=$SROOT/bin/cmake

# SSL for python
SSL_CERT_FILE=$SROOT/lib/python3.10/site-packages/certifi/cacert.pem

# Suppress python pip version check
PIP_DISABLE_PIP_VERSION_CHECK=1

# MPI, if installed
if [ -d /usr/lib64/openmpi/bin ]; then
	PATH=/usr/lib64/openmpi/bin:$PATH
fi

# GCC
which gcc 2>/dev/null > /dev/null && : ${GCC_VERSION=`gcc --version | head -1 | cut -d ' ' -f 3`}

# GotoBLAS
OMP_NUM_THREADS=1

# OpenCL
IFS=:
for p in ${LD_LIBRARY_PATH}
do
  if [ -e ${p}/libOpenCL.so ]; then
    OpenCL=${p}/libOpenCL.so
    break
  fi
done
unset IFS
if [ -z ${OPENCL_VENDOR_PATH} ]; then
    if [ -d /etc/OpenCL/vendors ]; then
        OPENCL_VENDOR_PATH=/etc/OpenCL/vendors
    else
        OPENCL_VENDOR_PATH=${SROOTBASE}/../distrib/OpenCL_$OS_ARCH/etc/OpenCL/vendors
    fi
else
    OPENCL_VENDOR_PATH=""
fi
if [ -z ${OpenCL} ]; then
    LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${SROOTBASE}/../distrib/OpenCL_$OS_ARCH/lib/$OS_ARCH
fi

# PGPLOT
if [ -f $SROOT/share/pgplot/grfont.dat ]; then
    PGPLOT_DIR=${SROOT}/share/pgplot
    PGPLOT_DEV=/xwin
fi

# Healpix
HEALPIX=$SROOT
HEALPIXDATA=$SROOT/share/healpix/

for name in SROOTBASE SROOT SITE_CMAKE_DIR PATH MANPATH PKG_CONFIG_PATH LD_LIBRARY_PATH PYTHONPATH CMAKE_PREFIX_PATH CMAKE_BIN OS_ARCH GCC_VERSION OMP_NUM_THREADS OPENCL_VENDOR_PATH CC CXX FC PGPLOT_DIR PGPLOT_DEV HEALPIX HEALPIXDATA SSL_CERT_FILE PIP_DISABLE_PIP_VERSION_CHECK
do
  eval VALUE=\$$name
  if [ "$name" != "OMP_NUM_THREADS" ]; then
	VALUE=\"$VALUE\"
  fi
  case ${SHELL##*/} in 
	tcsh)
		echo 'setenv '$name' '$VALUE' ;' ;;
	csh)
		echo 'setenv '$name' '$VALUE' ;' ;;
	*)
		echo 'export '$name=$VALUE' ;' ;;
  esac
done

