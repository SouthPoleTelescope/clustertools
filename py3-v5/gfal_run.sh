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

if [ -z "$SPT_USE_PROXY" ]; then
    if [ -z "$_CONDOR_CREDS" ] || [ ! -e "$_CONDOR_CREDS" ]; then
        TOKEN_FILE=`token-info -path`
        if [ -z "$TOKEN_FILE" ]; then
            echo "Missing grid token, please use token-init to generate one"
            exit 1
        fi

        timeleft=`token-info -timeleft`
        if [[ $timeleft -le 0 ]]; then
            echo "Grid token $GRID_USER_TOKEN is out of date, please generate a new one using token-init"
            exit 1
        fi

        export BEARER_TOKEN=`cat $TOKEN_FILE`
    else
        TOKEN_FILE="$_CONDOR_CREDS/scitokens.use"
        if [ ! -e $TOKEN_FILE ]; then
            echo "Missing condor token file $TOKEN_FILE"
            exit 1
        fi

        export BEARER_TOKEN=$(jq '.access_token' $TOKEN_FILE | tr -d '"')
    fi

    voms-proxy-destroy &> /dev/null
    unset X509_USER_PROXY
fi

set -e
exec $func $args
