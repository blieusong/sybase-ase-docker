FROM sybase/ase-server-install

COPY --chown=sybase ressources/entrypoint.sh /home/sybase/bin/
# compressed default database (because install is too slow)
COPY --chown=sybase dbdata/db_setup/ /opt/sap/
COPY --chown=sybase dbdata/data.tar.gz /tmp/

ENTRYPOINT [ "/home/sybase/bin/entrypoint.sh" ]