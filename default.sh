#!/bin/bash
# GatherPHP
#
# Don't touch this file here - it would prevent you to just "git pull"
# your GatherPHP installation.
#
# Author: Pascal Mathis <pmathis@snapserv.net>

# Set directories
# -------------------------
# Base directory of GatherPHP.
basedir=`dirname "$0"`
cd $basedir
basedir=`pwd`
# Directory where PHPs get installed to
instbasedir=`readlink -f "$basedir/inst"`
# Directory where all binaries are symlinked to
shbindir="$instbasedir/bin"
# Directory where the systemwide symlinks are created (bin)
symlinkdir="/usr/local/bin"
# Directory where the systemwide symlinks are created (sbin)
symlinksdir="/usr/local/sbin"

# Get all installed versions
VERSIONS=`ls ${shbindir}/php-[0-9]* | sed "s#${shbindir}/php-##"`
read -a VERSIONS_ARRAY <<<$VERSIONS

# Welcome message
echo 'Switch default PHP version'
echo '-----------------------------------'
echo 'With this script you can switch the system-wide'
echo 'standard PHP version. Please choose the desired'
echo 'PHP version from the list.'
echo ''

# Print version list
NUMBER=0
for VERSION in $VERSIONS; do
	echo "$NUMBER) $VERSION"
	NUMBER=$(($NUMBER + 1))
done
MAX_NUMBER=$NUMBER

# Let the user choose and check the selection
echo ''
read -p 'Select the desired PHP version: '
SELECTION=$REPLY

if [ $SELECTION -lt 0 ] || [ $SELECTION -gt $MAX_NUMBER ]; then
	echo 'Selection does not exist. Script aborted.'
	exit 1
fi
CHOOSEN_VERSION=${VERSIONS_ARRAY[$SELECTION]}

# Print installation progress message
echo ''
echo 'Installation progress'
echo '-----------------------------------'
echo "Choosen version: $VERSION"
echo ""

# [Function] resolveLink
function resolveLink {
	RESULT=`readlink -f "$1"`
	if [ "$RESULT" != "$1" ]; then
		echo "$RESULT"
	else
		echo "FAILED-$1"
	fi
}

# Resolve real paths to binaries
PHP_BINARY=`resolveLink "$shbindir/php-$CHOOSEN_VERSION"`
PHP_CGI_BINARY=`resolveLink "$shbindir/php-cgi-$CHOOSEN_VERSION"`
PHP_FPM_BINARY=`resolveLink "$shbindir/php-fpm-$CHOOSEN_VERSION"`
PHP_CONFIG_BINARY=`resolveLink "$shbindir/php-config-$CHOOSEN_VERSION"`
PHPIZE_BINARY=`resolveLink "$shbindir/phpize-$CHOOSEN_VERSION"`

PEAR_BINARY=`resolveLink "$shbindir/pear-$CHOOSEN_VERSION"`
PEARDEV_BINARY=`resolveLink "$shbindir/peardev-$CHOOSEN_VERSION"`
PECL_BINARY=`resolveLink "$shbindir/pecl-$CHOOSEN_VERSION"`
PHAR_BINARY=`resolveLink "$shbindir/phar-$CHOOSEN_VERSION"`

# [Function] symlink
function symlink {
	if [[ "$1" != *FAILED-* ]] || [ -e "$1" ]; then
		ln -fs "$1" "$2"
		if [ $? -gt 0 ]; then
			echo "Could not create symlink $1"
			echo "Maybe you don't have the necessary permissions?"
			exit 2
		else
			echo "Created symlink $1"
		fi
	else
		binary=`echo $binary | sed "s#FAILED-##"`
		binary=`basename "$1"`
		echo "NOTICE: No $binary binary found." >&2
	fi
}

# Create symlinks
symlink "$PHP_BINARY" "$symlinkdir/php"
symlink "$PHP_CGI_BINARY" "$symlinkdir/php-cgi"
symlink "$PHP_FPM_BINARY" "$symlinksdir/php-fpm"
symlink "$PHP_CONFIG_BINARY" "$symlinkdir/php-config"
symlink "$PHPIZE_BINARY" "$symlinkdir/phpize"

symlink "$PEAR_BINARY" "$symlinkdir/pear"
symlink "$PEARDEV_BINARY" "$symlinkdir/peardev"
symlink "$PECL_BINARY" "$symlinkdir/pecl"
symlink "$PHAR_BINARY" "$symlinkdir/phar"

# Done
echo ''
echo "System-wide standard PHP version switched to: $CHOOSEN_VERSION"
exit 0