Sybase (SAP) ASE Server image
=================================

Dockerfile for creating a Docker container running an ASE server.

Installer needs to be obtained from SAP here (it takes minutes to register, 
and SAP doesn't look too much at the details you provide):

- https://www.sap.com/cmp/td/sap-ase-enterprise-edition-trial.html 

If you want to get started immediately, you can try to pull the image I share
on Docker Hub (see Getting Started).

# Requirements
You will need a recent x64 Linux Docker host with
- at *least* 1GB of free disk space
- 4GB of RAM for the ASE server (you can change this in the ressource file)

# Getting Started
I share the image on Docker Hub : 
https://hub.docker.com/repository/docker/blieusong/sybase-ase.

You can get started by simply firing up **docker-compose**:

```
docker-compose up -d
```

That docker-compose binds a local volume (**sybase-data**) to the container,
so make sure `/var/lib/docker` has enough space to host your databases.

You can then access the ASE server on port 5000 of the Docker host.

# Creating Your Own Database
The image (**blieusong/ase-server**) I share is configured with 4k pagesize and
*iso_1* charset. You can build the Dockerfiles yourself to use different settings.

1. Update `ressources/ase.rs` according to your needs,
2. Build the Docker image. The **ASE_INSTALL_TGZ** variable can also be set in 
   the `Dockerfile` itself prior to running that command.

    ```bash
    $ docker build --build-arg ASE_INSTALL_TGZ="http://whatever.com/ASE_Suite.linuxamd64.tgz" -t blieusong/ase-server .
    ```

# Checking That It Works
Once the container (and hence the database server) is fired up, try to open a
database session. For example, using [FreeTDS](https://www.freetds.org)'s 
**fisql**:

1. Update your `/usr/local/etc/freetds.conf` to add the following entry:

    ```
    [DB_TEST]
        host = localhost
        port = 5000
        tds version = 5.0
    ```

2. Then use **fisql** to start a session:

    ```console
    $ fisql -Usa -Psybase -SDB_TEST
    Changed database context to 'master'.

    1>> select @@version
    2>> go

    ----------------------------------------------------------------------------------------------------------------------------------  -----------------------------------------------------------------------------------------------------------------------------
    Adaptive Server Enterprise/16.0 SP03 PL02/EBF 27415 SMP/P/x86_64/SLES 11.1/ase160sp03pl02x/3096/64-bit/FBO/Fri Oct  6 04:51:57  2017

    (1 rows affected)
    1>>
    ```

# Technical Details

Feel free to change these in `ase.rs` in the `ressources` folder.

## Installation

- Container hostname (on the sybase-bridge network): ase-server
- ASE installation folder: `/opt/sap`
- devices folder: `/data` on the container, mapped to `$HOME/sybase/data` on the 
  host
## Created Database

- Dataserver name: DB_TEST
- user: sa
- password: sybase
- pagesize: 2048

## Ressource Allocation

- Memory: 2GB
- CPUs: 2

## Charset

I left **iso_1** which comes by default, because I use that at work. But you 
may want to switch it to something more modern like **UTF-8**.

## Interface or freetds.conf file

If you have a Sybase client, add the following entry to the `interface` file 
to connect to the database from the Linux host

```
DB_TEST
    master tcp ether localhost 5000
    query tcp ether localhost 5000
```

If you use [FreeTDS](https://www.freetds.org), the `interface` file will do 
too, but you can also add that entry to `freetds.conf`

```
[DB_TEST]
    host = localhost
    port = 5000
    tds version = 5.0
```

# References

Adapted from:

- https://github.com/Naaooj/sap-as-docker
- https://github.com/dstore-dbap/sap-ase-docker
- https://github.com/nguoianphu/docker-sybase

The SAP ASE installation guide can also come in handy if you want to reuse 
this image and tweak the settings:

- https://help.sap.com/viewer/23c3bb4a29be443ea887fa10871a30f8/16.0.4.0/en-US
