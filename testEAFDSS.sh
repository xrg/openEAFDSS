#!/bin/bash

#DEVICE="DUMMY"
DEVICE="LAN"
#DEBUG="-v"
DEBUG=""

echo -n " * SIGN         --> "
SIGN=`./OpenEAFDSS.pl $DEBUG -n $DEVICE -e "SIGN invoice.txt" 2>&1`
echo $SIGN
sleep 2


echo -n " * SET TIME     --> "
CURTIME=`date +"%d%m%y/%H%M%S"`
TIME=`./OpenEAFDSS.pl $DEBUG -n $DEVICE -e "TIME $CURTIME" 2>&1`
echo $TIME

echo -n " * GET TIME     --> "
TIME=`./OpenEAFDSS.pl $DEBUG -n $DEVICE -e TIME 2>&1`
echo $TIME

echo -n " * STATUS       --> "
STATUS=`./OpenEAFDSS.pl $DEBUG -n $DEVICE -e STATUS 2>&1`
echo $STATUS

echo -n " * REPORT       --> "
REPORT=`./OpenEAFDSS.pl $DEBUG -n $DEVICE -e REPORT 2>&1`
echo $REPORT

echo -n " * INFO         --> "
INFO=`./OpenEAFDSS.pl $DEBUG -n $DEVICE -e INFO 2>&1`
echo $INFO

echo -n " * SET HEADERS  --> "
HEADERS=`./OpenEAFDSS.pl $DEBUG -n $DEVICE -e "HEADERS 0/H01/0/H02/0/H03/0/H04/0/H05/0/H06/" 2>&1`
echo $HEADERS

echo -n " * GET HEADERS  --> "
HEADERS=`./OpenEAFDSS.pl $DEBUG -n $DEVICE -e HEADERS 2>&1`
echo $HEADERS
