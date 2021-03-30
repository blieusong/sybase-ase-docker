#!/bin/bash
. /opt/sap/SYBASE.sh

ret=0
# if database doesn't exist, we create it from our premade package
if [ ! -f "/data/master.dat" ]; then
    cd /
    tar -xzf /tmp/data.tar.gz --no-same-owner
    ret=$?
    cd -
fi

if [ $ret -ne 0 ]; then
    echo "Error while extracting database files. Exiting."
    exit 1
fi

/home/sybase/bin/ase_start.sh DB_TEST

while true; do sleep 3000; done
#tail -f $SYBASE/$SYBASE_ASE/install/DB_TEST.log
