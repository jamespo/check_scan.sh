# check_scan.sh

An unofficial nmap scanner plugin for nagios. Originally by  [Mark Stigley](https://www.altsec.info/check_scan.html).

This fork has 2 additional features:

1.  Specify different base directory with BASEDIR environment variable
2. Specify host is IPv6 with trailing "-6" argument

Example Usage:

    check_scan.sh DUMMY google.com -6
    
    BASEDIR=/var/lib/scancheck check_scan.sh DUMMY facebook.com