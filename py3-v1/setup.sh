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
PYTHONPATH=$SROOT/lib/python3.5/site-packages:$PYTHONPATH
MANPATH=$SROOT/man:$SROOT/share/man:$MANPATH

# MPI, if installed
if [ -d /usr/lib64/openmpi/bin ]; then
	PATH=/usr/lib64/openmpi/bin:$PATH
fi

# GotoBLAS
GOTO_NUM_THREADS=1

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
if [ -f $SROOT/share/grfont.dat ]; then
    PGPLOT_DIR=${SROOT}/share/pgplot
    PGPLOT_DEV=/xwin
fi

for name in SROOTBASE SROOT SITE_CMAKE_DIR PATH MANPATH PKG_CONFIG_PATH LD_LIBRARY_PATH PYTHONPATH OS_ARCH GCC_VERSION GOTO_NUM_THREADS OPENCL_VENDOR_PATH PGPLOT_DIR PGPLOT_DEV CC CXX FC
do
  eval VALUE=\$$name
  case ${SHELL##*/} in 
	tcsh)
		echo 'setenv '$name' '\"$VALUE\"' ;' ;;
	csh)
		echo 'setenv '$name' '\"$VALUE\"' ;' ;;
	*)
		echo 'export '$name=\"$VALUE\"' ;' ;;
  esac
done

