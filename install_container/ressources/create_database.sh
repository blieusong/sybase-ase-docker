#!/bin/bash

. /opt/sap/SYBASE.sh

# Create database with options defined in ase.rs
$SYBASE/$SYBASE_ASE/bin/srvbuildres -r /home/sybase/cfg/ase.rs -D /home/sybase/ase