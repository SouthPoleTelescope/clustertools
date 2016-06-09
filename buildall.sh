#!/bin/sh

DIR=$(echo "${0%/*}")
SBASE=$(cd "$DIR" && echo "$(pwd -L)")

mkdir -p $SBASE/buildlogs

for toolset in py2-v1; do (
	eval `$SBASE/$toolset/setup.sh | grep -w -e OS_ARCH -e SROOT`
	logfile=$SBASE/buildlogs/$toolset-$OS_ARCH-`date | tr ' ' _`

	if [ ! -d $SROOT ]; then
		mkdir -p $1/build
		ln -s $1/build $SROOT
		fakesroot=1
	else
		fakesroot=0
	fi

	(
	# Install/update tools. This cannot fail.
	(eval `$SBASE/$toolset/setup.sh` && $SROOTBASE/tools/bootstrap_platform_tools.sh $1/tools) || exit 1

	# Clean scratch space (especially in case of a failed build)
	rm -rf $1
); done

