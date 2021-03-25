#!/bin/sh
. /opt/sap/SYBASE.sh

/home/sybase/bin/ase_start.sh DB_TEST

tail -f /home/sybase/ase/$SYBASE_ASE/install/DB_TEST.log