#!/bin/sh

case $OS_ARCH in
    RHEL_9_x86_64)
        OSG_ARCH=el9-x86_64
        OSG_VERSION=23-main
        ;;
    RHEL_8_x86_64)
        OSG_ARCH=el8-x86_64
        OSG_VERSION=23-main
        ;;
    RHEL_7_x86_64)
        OSG_ARCH=el7-x86_64
        OSG_VERSION=3.6
        ;;
    *)
        echo "Unknown architecture"
        exit 1
        ;;
esac

func=`basename $0`
args=$@

for pth in `echo $PATH|tr ":" "\n"`; do
    if [[ $pth = $SROOTBASE* ]]; then
        continue
    fi
    NEWPATH=$NEWPATH:$pth
done
export PATH=$NEWPATH
unset NEWPATH PYTHONPATH LD_LIBRARY_PATH PERL5LIB
source /cvmfs/oasis.opensciencegrid.org/osg-software/osg-wn-client/$OSG_VERSION/current/$OSG_ARCH/setup.sh

exec $func $args
