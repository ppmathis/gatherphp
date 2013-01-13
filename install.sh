#!/bin/bash
# GatherPHP
#
# Don't touch this file here - it would prevent you to just "git pull"
# your GatherPHP installation.
#
# Author: Pascal Mathis <pmathis@snapserv.net>

# Parse command line arguments
# -------------------------
source helpers.sh
parse_args $1
if [ $? -ne 0 ]; then
	echo 'You need to specify atleast a valid php version' >&2
	exit 1
fi

# Set directories
# -------------------------
# Base directory of GatherPHP.
basedir=`dirname "$0"`
cd $basedir
basedir=`pwd`
# Directory for PHP sources
srcdir="$basedir/src/php-$VERSION"
# Directory with source archives
bzipsdir="$basedir/src/bzips"
# Directory where PHPs get installed to
instbasedir=`readlink -f "$basedir/inst"`
# Directory where this specific PHP version gets installed into
instdir="$instbasedir/php-$VERSION"
# Directory where all binaries are symlinked to
shbindir="$instbasedir/bin"

# Print installation overview
# -------------------------
echo 'Installation overview'
echo '-----------------------------------'
echo "PHP version: $VERSION"
echo "Source directory: $srcdir"
echo "Installation directory: $instdir"
echo ''
read -p 'Do you want to continue (Y/N)? '
[ "$(echo $REPLY | tr [:upper:] [:lower:])" == "y" ] || exit
echo 'Installation progress'
echo '-----------------------------------'

# Download & Extract PHP source
# -------------------------
# Check if PHP source was already downloaded & extracted
if [ ! -d "$srcdir" ]; then
	echo 'Source directory does not exist; trying to extract'
	srcfile="$bzipsdir/php-$SHORT_VERSION.tar.bz2"

	# Check if source file exists, if not try to fetch it
	if [ ! -e "$srcfile" ]; then
		echo "Source file not found: $srcfile"

		# Try to download version from museum
		url="http://museum.php.net/php$VMAJOR/php-$SHORT_VERSION.tar.bz2"
		wget -P "$bzipsdir" -O "$srcfile" "$url"
		if [ ! -f "$srfile" ]; then
			echo "Fetching sources from museum failed: $url"

			# Try the real download now
			url="http://www.php.net/get/php-$SHORT_VERSION.tar.bz2/from/this/mirror"
			wget -P "$bzipsdir" -O "$srcfile" "$url"
		fi
		if [ ! -s "$srcfile" -a -f "$srcfile" ]; then
			rm "$srcfile"
			echo "Fetching sources failed: $url" >&2
			exit 2
		fi
	fi

	# Extract the source file
	tar xjvf "$srcfile" --show-transformed-names --xform 's#^[^/]*#src/php-'"$VERSION"'#'
	if [ $? -ne 0 ]; then
		echo "Failed to extract source file: $srcfile" >&2
		exit 2
	fi
else
	echo "Found source directory: $srcdir"
fi

# Read configuration flags
# -------------------------
source options.sh "$VERSION" "$VMAJOR" "$VMINOR" "$VPATCH" "$FLAGS"
cd "$srcdir"

# Only configure & make during the first install of a new version
# or after some changes were made in configuration
tstamp=0
if [ -f "config.nice" -a -f "config.status" ]; then
	tstamp=`stat -c '%Y' config.status`
fi

echo "Last configuration change: $config_timestamp";
echo "Last ./configure: $tstamp";
if [ $config_timestamp -gt $tstamp ]; then
	# Configure PHP
	if [ $DEBUG = 1 ]; then
		config_options="--enable-debug $config_options"
	fi
	if [ $PEAR = 1 ]; then
		config_options="--with-pear=\"$instdir/pear\""
	fi
	if [ $ARCH32 = 1 ]; then
		export CFLAGS="$CFLAGS -m32"
		export CXXFLAGS="$CXXFLAGS -m32"
		export LDFLAGS="$LDFLAGS -m32"
	fi
	if [ $ZTS = 1 ]; then
		config_options="--enable-maintainer-zts $config_options"
	fi

	./configure $config_options \
		--prefix="$instdir" \
		--exec-prefix="$instdir"

	if [ $? -gt 0 ]; then
		echo 'configure.sh failed' >&2
		exit 3
	fi
else
	echo 'Skipping execution of ./configure'
fi

# Check configure status
# -------------------------
# Check that no unknown options have been used
unknown_options=
if [ -e "config.status" ]; then
	unknown_options=`sed -ne '/Following unknown configure options were used/,/for available options/p' config.status | sed -n -e '$d' -e '/^$/d' -e '3,$p'`
fi
if [ -z "$unknown_options" -a -e "config.log" ]; then
	unknown_options=`sed -n -r -e 's/configure:[^\020]+WARNING: unrecognized options: //p' config.log`
fi

# Abort if some unknown options were found
if [ -n "$unknown_options" ]; then
	if [ $config_timestamp -le $tstamp ]; then
		echo '' >&2
		echo 'ERROR: The following unrecognized configure options were used:' >&2
		echo '' >&2
		echo $unknown_options >&2
		echo '' >&2
		echo "Check 'configure --help' for available options." >&2
	fi
	echo 'Please fix your configure options and try again.' >&2
	exit 3
fi

# Build and install PHP
# -------------------------
# Clean working directory and build PHP
if [ $config_timestamp -gt $tstamp -o ! -f sapi/cli/php ]; then
	make clean
	make
	if [ $? -gt 0 ]; then
		echo 'make failed.'
		exit 4
	fi
else
	echo 'Skipping executing of make'
fi

# Install PHP
make install
if [ $? -gt 0 ]; then
	echo 'make install failed.'
	exit 5
fi

# Create PHP configuration
# -------------------------
# Apply custom PHP.ini if available
echo ''
initarget="$instdir/lib/php.ini"
useCustom=0

for suffix in \
	"" \
	"-$VMAJOR" \
	"-$VMAJOR.$VMINOR" \
	"-$VMAJOR.$VMINOR.$VPATCH" \
	"-$VMAJOR$FLAGS" \
	"-$VMAJOR.$VMINOR$FLAGS" \
	"-$VMAJOR.$VMINOR.$VPATCH$FLAGS" \
; do
	custom="custom/php$suffix.ini"
	if [ -e "$custom" ]; then
		if [ $useCustom -eq 0 ]; then
			useCustom=1
			sed -e 's#$ext_dir#'"$ext_dir"'#' "$custom" > "$initarget"
			echo "Using custom php.ini: $custom"
		else
			sed -e 's#$ext_dir#'"$ext_dir"'#' "$custom" >> "$initarget"
			echo "Appending custom php.ini: $custom"
		fi
	fi
done

# If no custom PHP.ini was found, copy the default one
if [ $useCustom -eq 0 ]; then
	if [ -f "php.ini-recommended" ]; then
		cp "php.ini-recommended" "$initarget"
		echo "Copied php.ini-recommended to $initarget"
	elif [ -f "php.ini-development" ]; then
		cp "php.ini-development" "$initarget"
		echo "Copied php.ini-recommended to $initarget"
	else
		echo 'No php.ini file found'
		echo "Please copy it manually to $instdir/lib/php.ini"
	fi
fi

echo ''

# Create binary symlinks
# -------------------------
# Create bin directory if necessary
[ ! -d "$shbindir" ] && mkdir "$shbindir"
if [ ! -d "$shbindir" ]; then
	echo 'Cannot create shared binary directory.' >&2
	exit 6
else
	# Delete old symlinks if there are some
	rm -f "$shbindir/php-$VERSION"
	rm -f "$shbindir/php-cgi-$VERSION"
	rm -f "$shbindir/phpconfig-$VERSION"
	rm -f "$shbindir/phpize-$VERSION"

	rm -f "$shbindir/pear-$VERSION"
	rm -f "$shbindir/peardev-$VERSION"
	rm -f "$shbindir/pecl-$VERSION"
	rm -f "$shbindir/phar-$VERSION"
fi

# Symlink PHP executable
bphp="$instdir/bin/php"
bphpgcno="$instdir/bin/php.gcno"
if [ -f "$bphp" ]; then
	ln -fs "$bphp" "$shbindir/php-$VERSION"
	echo "Created symlink $shbindir/php-$VERSION"
elif [ -f "$bphpgcno" ]; then
	ln -fs "$bphpgcno" "$shbindir/php-$VERSION"
	echo "Created symlink $shbindir/php-$VERSION"
else
	echo 'No php binary found.' >&2
	exit 7
fi

# [Function] symlink
function symlink {
	if [ -e "$1" ]; then
		ln -fs "$1" "$2"
		echo "Created symlink $1"
	else
		binary=`basename "$1"`
		echo "WARNING: No $binary binary found." >&2
	fi
}

# Symlink PHP cgi executable
bphpcgi="$instdir/bin/php-cgi"
bphpcgigcno="$instdir/bin/php-cgi.gcno"
if [ -f "$bphpcgi" ]; then
	symlink "$bphpcgi" "$shbindir/php-cgi-$VERSION"
elif [ -f "$bphpcgigcno" ]; then
	symlink "$bphpcgigcno" "$shbindir/php-cgi-$VERSION"
else
	echo 'WARNING: No php-cgi binary found.' >&2
fi

# Symlink php-config & phpize
symlink "$instdir/bin/php-config" "$shbindir/php-config-$VERSION"
symlink "$instdir/bin/phpize" "$shbindir/phpize-$VERSION"

# Finish PEAR installation if it was installed
if [ -e "$instdir/bin/pear" ]; then
	symlink "$instdir/bin/pear" "$shbindir/pear-$VERSION"
	symlink "$instdir/bin/peardev" "$shbindir/peardev-$VERSION"
	symlink "$instdir/bin/pecl" "$shbindir/pecl-$VERSION"
fi

# Symlink PHAR if available
if [ -e "$instdir/bin/phar.phar" ]; then
	symlink "$instdir/bin/phar.phar" "$shbindir/phar-$VERSION"
fi

# Post-install stuff
# -------------------------
# Execute post-install scripts if available
echo ''
echo 'Executing post-install scripts'
echo '-----------------------------------'
cd "$basedir"

for suffix in \
	"" \
	"-$VMAJOR" \
	"-$VMAJOR.$VMINOR" \
	"-$VMAJOR.$VMINOR.$VPATCH" \
	"-$VMAJOR$FLAGS" \
	"-$VMAJOR.$VMINOR$FLAGS" \
	"-$VMAJOR.$VMINOR.$VPATCH$FLAGS" \
; do
	post="custom/post-install$suffix.sh"
	if [ -e "$post" ]; then
		echo ''
		echo "Running commands from '$post'"
		/bin/bash $post "$VERSION" "$instdir" "$shbindir"
	fi
done

# Exit
echo ''
echo "PHP $VERSION installed."
exit 0