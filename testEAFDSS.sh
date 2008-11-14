#!/bin/bash

echo -n " * SIGN         --> "
SIGN=`./OpenEAFDSS-Util.pl -n WLAN -e "SIGN invoice.txt"`
echo $SIGN
sleep 2

echo -n " * SET TIME     --> "
CURTIME=`date +"%d%m%y/%H%M%S"`
TIME=`./OpenEAFDSS-Util.pl -n WLAN -e "TIME $CURTIME"`
echo $TIME

echo -n " * GET TIME     --> "
TIME=`./OpenEAFDSS-Util.pl -n WLAN -e TIME`
echo $TIME

echo -n " * STATUS       --> "
STATUS=`./OpenEAFDSS-Util.pl -n WLAN -e STATUS`
echo $STATUS

echo -n " * REPORT       --> "
REPORT=`./OpenEAFDSS-Util.pl -n WLAN -e REPORT`
echo $REPORT

echo -n " * INFO         --> "
INFO=`./OpenEAFDSS-Util.pl -n WLAN -e INFO`
echo $INFO

echo -n " * SET HEADERS  --> "
HEADERS=`./OpenEAFDSS-Util.pl -n WLAN -e "HEADERS 0/H01/0/H02/0/H03/0/H04/0/H05/0/H06/"`
echo $HEADERS

echo -n " * GET HEADERS  --> "
HEADERS=`./OpenEAFDSS-Util.pl -n WLAN -e HEADERS`
echo $HEADERS
