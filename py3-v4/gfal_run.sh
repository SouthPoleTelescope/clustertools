#!/bin/sh

# Setup OSG environment
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
        echo "Unknown architecture" 1>&2
        exit 1
        ;;
esac

OSG_PATH=/cvmfs/oasis.opensciencegrid.org/osg-software/osg-wn-client/$OSG_VERSION/current/$OSG_ARCH
if [ ! -e $OSG_PATH ]; then
    echo "Missing OSG software" 1>&2
    exit 1
fi

for pth in `echo $PATH|tr ":" "\n"`; do
    if [[ $pth = $SROOTBASE* ]]; then
        continue
    fi
    NEWPATH=$NEWPATH:$pth
done
export PATH=$NEWPATH
unset NEWPATH PYTHONPATH LD_LIBRARY_PATH PERL5LIB
source $OSG_PATH/setup.sh

# Setup grid authentication
if [ -n "$_CONDOR_CREDS" ] && [ -e "$_CONDOR_CREDS" ]; then
    # Native credentials in a condor job

    TOKEN_FILE="$_CONDOR_CREDS/scitokens.use"
    if [ ! -e $TOKEN_FILE ]; then
        echo "Missing condor token file $TOKEN_FILE" 1>&2
        exit 1
    fi

    export BEARER_TOKEN=$(jq '.access_token' $TOKEN_FILE | tr -d '"')

elif [ -z "$SPT_USE_PROXY" ]; then
    # User-generated token

    TOKEN_FILE=`token-info -path`
    if [ -z "$TOKEN_FILE" ]; then
        echo "Missing grid token, please use token-init to generate one" 1>&2
        exit 1
    fi

    timeleft=`token-info -timeleft`
    if [[ $timeleft -le 0 ]]; then
        echo "Grid token $TOKEN_FILE is out of date, please generate a new one using token-init" 1>&2
        exit 1
    fi

    export BEARER_TOKEN=`cat $TOKEN_FILE`
fi

# Token overrides X509 certificate if both are present
if [ -n "$BEARER_TOKEN" ]; then
    voms-proxy-destroy &> /dev/null
    unset X509_USER_PROXY
fi

func=`basename $0`
if [ "$func" == "gfal_run.sh" ]; then
    echo "Cannot execute $0 directly, must be aliased to a gfal command-line tool" 1>&2
    exit 1
fi

args=$@

set -e
exec $func $args
