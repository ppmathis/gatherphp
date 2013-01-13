#!/bin/bash
# GatherPHP
#
# Don't touch this file here - it would prevent you to just "git pull"
# your GatherPHP installation.
#
# Author: Pascal Mathis <pmathis@snapserv.net>

# Parses the command line arguments
# -------------------------
parse_args() {
	# Was string empty? Abort
	v=`echo "$1" | sed -e 's/[-.]/ /g'`
	if [ -z `echo "$v" | sed -e 's/ //g'` ]; then
		return 1
	fi

	# Parse PHP version
	VMAJOR=`echo "$v" | cut -d ' ' -f 1`
	VMINOR=`echo "$v" | cut -d ' ' -f 2`
	VPATCH=`echo "$v" | cut -d ' ' -f 3`
	v=`echo "$v" | cut -d ' ' -f 4-`

	# Parse optional flags
	DEBUG=0
	PEAR=0
	ZTS=0
	ARCH32=0
	for p in $v; do
		case $p in
			debug)		DEBUG=1;;
			pear)		PEAR=1;;
			32bits)		ARCH32=1;;
			zts)		ZTS=1;;
			*)			echo "Unsupported token '$p'"; return 2;;
		esac
	done

	# Create full version string which contains
	# the php version with all flags.
	FLAGS=""
	if [ $DEBUG = 1 ]; then
		FLAGS="$FLAGS-debug"
	fi
	if [ $PEAR = 1 ]; then
		FLAGS="$FLAGS-pear"
	fi
	if [ $ARCH32 = 1 ]; then
		FLAGS="$FLAGS-32bits"
	fi
	if [ $ZTS = 1 ]; then
		FLAGS="$FLAGS-zts"
	fi
	VERSION="$VMAJOR.$VMINOR.$VPATCH"
	SHORT_VERSION="$VERSION"
	VERSION="$VERSION$FLAGS"

	return 0
}
