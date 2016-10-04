#!/bin/sh

# .bash_profile

if [ -x /usr/bin/lsb_release ]; then
	DISTRIB=`lsb_release -si | tr ' ' '_'`
	VERSION=`lsb_release -sr`
	CPU=`uname -m`
else
	DISTRIB=`uname -s`
	VERSION=`uname -r`
	CPU=`uname -m`
fi

# Map binary compatible operating systems and versions onto one another
case $DISTRIB in
	"RedHatEnterpriseClient" | "RedHatEnterpriseServer" | "ScientificSL" | "Scientific" | "CentOS")
		DISTRIB="RHEL"
		VERSION=`lsb_release -sr | cut -d '.' -f 1`
		;;
	"Ubuntu")
		VERSION=`lsb_release -sr | cut -d '.' -f 1`
		;;
	"FreeBSD")
		VERSION=`uname -r | cut -d '.' -f 1`
		CPU=`uname -p`
		;;
	"Darwin")
		VERSION=`uname -r | cut -d '.' -f 1`
		;;
	"Linux")
		# Damn. Try harder with the heuristics.
		if echo $VERSION | grep -q '\.el7\.\?'; then
			DISTRIB="RHEL"
			VERSION=7
		elif echo $VERSION | grep -q '\.el6\.\?'; then
			DISTRIB="RHEL"
			VERSION=6
		elif echo $VERSION | grep -q '\.el5\.\?'; then
			DISTRIB="RHEL"
			VERSION=5
		fi
esac

: ${OS_ARCH=${DISTRIB}_${VERSION}_${CPU}}; export OS_ARCH
which gcc 2>/dev/null > /dev/null && : ${GCC_VERSION=`gcc --version | head -1 | cut -d ' ' -f 3`}; export GCC_VERSION
