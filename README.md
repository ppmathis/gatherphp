# GatherPHP #

Manage multiple PHP versions easily and comfortably with GatherPHP.

## License ##
Apache License (version 2)

## Installation of GatherPHP ##
Just clone the git repository of gatherphp into some directory of your choice and you are good to go!

```bash
git clone git://github.com/NeoXiD/gatherphp.git
```

## Install a new PHP version ##
Just run the following command and a new PHP version will get installed:

```bash
# Example: ./install.sh 5.4.10
./install.sh [PHP Version]
```

**Notice:** Do *not* use sudo for installing new versions. Either put GatherPHP in a directory where you've got write access to or use an interactive shell. (```sudo -i```, ```sudo su```...)

GatherPHP will automatically fetch the correct archive, extract, configure and install it. But that is not all yet - you can append flags after the *PHP Version*, like here:

```bash
./install.sh 5.4.10-debug
./install.sh 5.4.10-debug-zts
```

The order of the flags does not matter - GatherPHP will sort them for you! These are all the available flags:

- **debug** compiles a version with debugging symbols
- **zts** enables thread safety
- **32bits** forces the creation of a 32bits version on a 64bit machine
- **pear** adds & installs PEAR support

After the installation, GatherPHP creates some symlinks in /inst/bin. If you will extend your $PATH variable so that it will point to /path/to/gatherphp/inst/bin, you can use commands like this:

```bash
php-5.4.10 ...
phpize-5.4.10-debug ...
pear-5.3.0 ...
```

## Configure options customization ##
Whenever you install a PHP version, GatherPHP will look for the following files in the **custom/** folder:

- **options-** *major.minor.patch-flags* **.sh** (e.g. ```options-5.4.10-debug-pear.sh```)
- **options-** *major.minor-flags* **.sh** (e.g. ```options-5.4-debug-pear.sh```)
- **options-** *major-flags* **.sh** (e.g. ```options-5-debug-pear.sh```)
- **options-** *major.minor.patch* **.sh** (e.g. ```options-5.4.10.sh```)
- **options-** *major.minor* **.sh** (e.g. ```options-5.4.sh```)
- **options-** *major* **.sh** (e.g. ```options-5.sh```)
- **options.sh**

The first file which can be found will be taken - other files will be ignored. While installating a PHP version, GatherPHP shows you which configure options file will be used. A options file should look like this:

```bash
#!/bin/bash
config_options="		\
--disable-all			\
--enable-session		\
--enable-filter			\
--disable-cgi			\
"
```

## php.ini customization ##
GatherPHP will also look for the following files in the **custom/** folder to generate a php.ini file:

- **php.ini**
- **php-** *major* **.ini** (e.g. ```php-5.ini```)
- **php-** *major.minor* **.ini** (e.g. ```php-5.4.ini```)
- **php-** *major.minor.patch* **.ini** (e.g. ```php-5.4.10.ini```)
- **php-** *major-flags* **.ini** (e.g. ```php-5-debug-pear.ini```)
- **php-** *major.minor-flags* **.ini** (e.g. ```php-5.4-debug-pear.ini```)
- **php-** *major.minor.patch-flags* **.ini** (e.g. ```php-5.4.10-debug-pear.ini```)

Other than during the configure options part, **all** the available ini files are merged together in the order specified as above.

## Post-installation scripts ##
GatherPHP also supports post-installation scripts for copying extensions, installating PEAR modules and so on. Again, it will look for the following files in the **custom/** folder:

- **post-install.sh**
- **post-install-** *major* **.sh** (e.g. ```post-install-5.sh```)
- **post-install-** *major.minor* **.sh** (e.g. ```post-install-5.4.sh```)
- **post-install-** *major.minor.patch* **.sh** (e.g. ```post-install-5.4.10.sh```)
- **post-install-** *major-flags* **.sh** (e.g. ```post-install-5-debug-pear.sh```)
- **post-install-** *major.minor-flags* **.sh** (e.g. ```post-install-5.4-debug-pear.sh```)
- **post-install-** *major.minor.patch-flags* **.sh** (e.g. ```post-install-5.4.10-debug-pear.sh```)

A post-installation script gets called with the following parameters:

```bash
/bin/bash script.sh [Installed Version] [Installation Directory] [Binary Directory]
```

- - -
GatherPHP - © 2013 P. Mathis (pmathis@snapserv.net)
