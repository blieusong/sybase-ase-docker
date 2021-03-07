#!/bin/bash
. /opt/sap/SYBASE.sh

SERVER_NAME=$1

echo -en "Stop server \e[0;34m${SERVER_NAME}\e[0m: "

isql -Usa -S${SERVER_NAME} -Psybase < $SYBASE/$SYBASE_ASE/upgrade/shutdown.sql > /dev/null

ret=$?

if [ ${ret} -ne 0 ]; then
    echo -e "\e[0;31mKO\e[0m"
    exit 1
fi

echo -e "\e[0;32mOK\e[0m"
exit 0
