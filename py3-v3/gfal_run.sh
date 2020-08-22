#!/bin/sh

case $OS_ARCH in
    RHEL_7_x86_64)
        OSG_ARCH=el7-x86_64
        ;;
    RHEL_6_x86_64)
        OSG_ARCH=el6-x86_64
        ;;
    *)
        echo "Unknown architecture"
        exit 1
        ;;
esac

func=`basename $0`
args=$@

unset PYTHONPATH LD_LIBRARY_PATH PERL5LIB
source /cvmfs/oasis.opensciencegrid.org/osg-software/osg-wn-client/current/$OSG_ARCH/setup.sh

exec $func $args
