Sybase (SAP) ASE Server image
=================================

Dockerfile for creating a Docker container running an ASE server.

Installer needs to be obtained from SAP here (it takes minutes to register, and SAP doesn't look too much at the details you provide):

- https://www.sap.com/cmp/td/sap-ase-enterprise-edition-trial.html 

# Foreword 
If you've ever needed that ASE server playground on which you could try new things but no one could create an instance for you (for many reasons), then this Docker image will help.

It gets you started instantly, if you pull the image I share on Docker Hub (see Getting Started).

# Requirements
You will need a recent x64 Linux Docker host with
- at *least* 1GB of free disk space
- 4GB of RAM for the ASE server (you can change this in the ressource file)
- A working **docker** and **docker-compose** (the [Docker website](https://docs.docker.com/engine/install/) can help)

# Getting Started
I share the image on Docker Hub : https://hub.docker.com/repository/docker/blieusong/sybase-ase.

You can get started by simply firing up **docker-compose**:

```
docker-compose up -d
```

That docker-compose binds a local volume (**sybase-data**) to the container, so make sure `/var/lib/docker` has enough space to host your databases.

You can then access the ASE server on port 5000 of the Docker host.

# Build Instructions
The image I share is configured with 4k pagesize and *iso_1* charset. You can build the Dockerfile yourself to choose different settings.

Building the `Dockerfile` only installs the ASE server binaries. You have to run the database creation *afterwards*. 

This two steps approach allows to have the database data outside the container itself.

1. Build the Docker image. The ASE installation in that build can take up to a dozen of minutes.

```console
$ docker build -t sybase/ase-server:latest .
```
Don't forget to set the **FILESERVER** environment variable in the `Dockerfile` to tell Docker where to get the ASE install archive.

You can also specify your fileserver from the command line instead of in the `Dockerfile`:

```console
$ docker build --build-arg FILESERVER="http://whatever.com/" -t sybase/ase-server:latest .
```

# Creating Your Own Database
The provider `Dockerfile` comes with a "preloaded" database in:

- `dbdata/dbsetup/`
- `dbdata/data.tar.gz`

That database is created using the `ase.rs` file's content as parameters.

To generate your own database, and incorporate it into your own docker image, follow these (tricky) steps:

1. Update `ase.rs` according to your needs.

2. Run the database creation script on the Docker image session. Make sure you bind `ase.rs`.

```
$ docker run \
    -v $HOME/sybase/data:/data \
    -v $HOME/sybase/ase:/home/sybase/ase \
    -v ressources/ase.rs:/home/sybase/cfg/ase.rs \
    -it blieusong/sybase-ase:latest \
    create_database.sh
```

The database and associated configuration files are created, respectively in your local `$HOME/sybase/data` and `$HOME/sybase/ase`.

3. Generate the database data archive

```
cd $HOME/sybase
tar -czf data.tar.gz data
```
and copy the `tar.gz` into the `dbdata` folder

4. Copy the config folder into the `dbdata` folder

```
rm -fr $YOUR_PROJECT_DIR/dbdata/db_setup
cp -r $HOME/sybase/ase $YOUR_PROJECT_DIR/dbdata/db_setup
```

At this stage, you can remove `$HOME/sybase` if you want.

5. replace `/home/sybase/ase` with `/opt/sap` (since we move the configuration files there in the Dockerfile) in every file under `db_setup/ASE-16-0`.

6. Rebuild the `Dockerfile`. After that the embedded database which is fired up at first launch shall have been created with your parameters.

# Checking That It Works

If you have proper clients installed, you can try to open a database session. For example, using [FreeTDS](https://www.freetds.org)'s **fisql**:

1. Update your `/usr/local/etc/freetds.conf` to add the following entry:

```
[DB_TEST]
    host = localhost
    port = 5000
    tds version = 5.0
```

Then use **fisql** to start a session:

```console
$ fisql -Usa -Psybase -SDB_TEST
Changed database context to 'master'.

1>> select @@version
2>> go

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Adaptive Server Enterprise/16.0 SP03 PL02/EBF 27415 SMP/P/x86_64/SLES 11.1/ase160sp03pl02x/3096/64-bit/FBO/Fri Oct  6 04:51:57 2017

(1 rows affected)
1>>
```

# Technical Details

Feel free to change these in `ase.rs` in the `ressources` folder.

## Installation

- Container hostname (on the sybase-bridge network): ase-server
- ASE installation folder: `/opt/sap`
- devices folder: `/data` on the container, mapped to `$HOME/sybase/data` on the host
- database installation folder: `/home/sybase/ase`

## Created Database

- Dataserver name: DB_TEST
- user: sa
- password: sybase
- pagesize: 4096

## Ressource Allocation

- Memory: 4GB
- CPUs: 2

## Charset

I left **iso_1** which comes by default, because I use that at work. But you may want to switch it to something more modern like **UTF-8**.

## Interface or freetds.conf file

If you have a Sybase client, add the following entry to the `interface` file to connect to the database from the Linux host

```
DB_TEST
    master tcp ether localhost 5000
    query tcp ether localhost 5000
```

If you use [FreeTDS](https://www.freetds.org), the `interface` file will do too, but you can also add that entry to `freetds.conf`

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

The SAP ASE installation guide can also come in handy if you want to reuse this image and tweak the settings:

- https://help.sap.com/viewer/23c3bb4a29be443ea887fa10871a30f8/16.0.4.0/en-US
