FROM ubuntu:focal

# define your own http file server here (or pass it as argument to docker build)
ARG FILESERVER=${YOUR_OWN_SERVER}

ENV ASE_INSTALL_TGZ=${FILESERVER}/ASE_Suite.linuxamd64.tgz

# needed by the ASE installer
RUN apt update \
    && apt -y install \
    curl \
    libaio1 \
    unzip

COPY ressources/response_file.txt /tmp/response_file.txt

# Installs ASE and then remove many useless junks
RUN cd /tmp \
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
    && cd /opt/sap/ASE-16_0/bin && rm asecfg ddlgen *java sqlloc sqlupgrade srvbuild 

RUN groupadd sybase \
    && useradd -g sybase -s /bin/bash sybase \
    && chown -R sybase:sybase /opt/sap

# RUN ["/bin/bash", "-c", "echo \"sybase\nsybase\" | (passwd sybase)"]

COPY --chown=sybase ressources/ase.rs /home/sybase/cfg/
COPY --chown=sybase ressources/create_database.sh /home/sybase/bin/
COPY --chown=sybase ressources/ase_start.sh /home/sybase/bin/
COPY --chown=sybase ressources/ase_stop.sh /home/sybase/bin/
COPY --chown=sybase ressources/entrypoint.sh /home/sybase/bin/
#trick to create the directory with proper rights.
COPY --chown=sybase ressources/ase.rs /home/sybase/ase/

ENV PATH=/home/sybase/bin:$PATH