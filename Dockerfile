FROM ubuntu:20.04

# path to the ASE server suite installer (ASE_Suite.linuxamd64.tgz)
ARG ASE_INSTALL_TGZ="http//www.yourserver.com/ASE_Suite.linuxamd64.tgz"

COPY ressources/response_file.txt /tmp/response_file.txt

# needed by the ASE installer
RUN apt update \
    && apt upgrade -y \
    && apt -y install \
    curl \
    libaio1 \
    unzip \
# Installs ASE and then remove useless stuffs
    && cd /tmp \
    && curl ${ASE_INSTALL_TGZ} | tar -xzf - \
    && ./setup.bin -f response_file.txt -i silent -DAGREE_TO_SAP_LICENSE=true -DRUN_SILENT=true \
    && rm -rf /tmp/* \
    && rm -fr /opt/sap/shared/SAPJRE-* \
    && rm -fr /opt/sap/shared/ase/SAPJRE-* \
    && rm -fr /opt/sap/jre64 \
    && rm -fr /opt/sap/sybuninstall \
    && rm -fr /opt/sap/jConnect-16_0 \
    && rm -fr /opt/sap/jutils-3_0 \
    && rm -fr /opt/sap/ASE-16_0/bin/diag* \
    && rm -fr /opt/sap/OCS-16_0/devlib* \
    && rm -fr /opt/sap/SYBDIAG \
    && rm -fr /opt/sap/COCKPIT-4 \
    && rm -fr /opt/sap/WS-16_0 \
    # we don't need non 64bit versions of the libs
    && rm -fr /opt/sap/OCS-16_0/bin32 \
    && rm -fr /opt/sap/OCS-16_0/lib3p \
    && rm -fr /opt/sap/OCS-16_0/lib/*[!6][!4].a \
    && rm -fr /opt/sap/OCS-16_0/lib/*[!6][!4].so \
    # remove graphical apps and java junks
    && cd /opt/sap/ASE-16_0/bin && rm asecfg ddlgen *java sqlloc sqlupgrade srvbuild \
# remove useless packages
    && apt -y remove curl unzip \
    && apt -y autoremove

RUN groupadd sybase \
    && useradd -g sybase -s /bin/bash sybase \
    && chown -R sybase:sybase /opt/sap

# RUN ["/bin/bash", "-c", "echo \"sybase\nsybase\" | (passwd sybase)"]
ENV PATH=/home/sybase/bin:$PATH

COPY --chown=sybase ressources/ase.rs /home/sybase/cfg/
COPY --chown=sybase ressources/ase_start.sh /home/sybase/bin/
COPY --chown=sybase ressources/ase_stop.sh /home/sybase/bin/

# We create the database itself but then zip it and delete
# the data folder to keep the image as small as possible.
# This archive is unpacked in /data upon first launch. /data
# should be bound to a Docker volume for persistence.
RUN . /opt/sap/SYBASE.sh \
    && $SYBASE/$SYBASE_ASE/bin/srvbuildres -r /home/sybase/cfg/ase.rs -D /opt/sap \
    && tar -czf /tmp/data.tar.gz /data \
    && rm -fr /data 

COPY --chown=sybase ressources/entrypoint.sh /home/sybase/bin/
