#!/bin/bash
# GatherPHP
#
# Don't touch this file here - it would prevent you to just "git pull"
# your GatherPHP installation.
#
# Author: Pascal Mathis <pmathis@snapserv.net>

VERSION=$1
VMAJOR=$2
VMINOR=$3
VPATCH=$4
FLAGS=$5

last="options.sh"
config_timestamp=`stat -c '%Y' options.sh`
config_options="		\
--disable-all			\
"

for suffix in \
	"" \
	"-$VMAJOR" \
	"-$VMAJOR.$VMINOR" \
	"-$VMAJOR.$VMINOR.$VPATCH" \
	"-$VMAJOR$FLAGS" \
	"-$VMAJOR.$VMINOR$FLAGS" \
	"-$VMAJOR.$VMINOR.$VPATCH$FLAGS" \
; do
	custom="custom/options$suffix.sh"
	if [ -e "$custom" ]; then
		tstamp=`stat -c '%Y' "$custom"`
		if [ $tstamp -gt $config_timestamp ]; then
			config_timestamp=$tstamp
		fi
		last=$custom
		source "$custom" "$VERSION" "$VMAJOR" "$VMINOR" "$VPATCH"
	fi
done

echo "Used configuration for $VERSION: $last"