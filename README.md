Sybase (SAP) ASE Server image
=================================

Dockerfile for creating a Docker container running an ASE server.

Adapted from:
- https://github.com/Naaooj/sap-as-docker
- https://github.com/dstore-dbap/sap-ase-docker
- https://github.com/nguoianphu/docker-sybase

Installer needs to be obtained from SAP here (it takes minutes to register, and SAP doesn't look too much at the details you provide):

- https://www.sap.com/cmp/td/sap-ase-enterprise-edition-trial.html 

The SAP ASE installation guide can also come in handy:

- https://help.sap.com/viewer/23c3bb4a29be443ea887fa10871a30f8/16.0.4.0/en-US

# Foreword 
If you've ever felt like you need that ASE server playground on which you could try new things but no one could create an instance for you (for many reasons), then this Docker image will help.

# Prerequisite

You will need a recent Linux Docker host with
- **docker**
- **docker-compose**
- *sudoer* rights or being part of the *docker* group

If you miss one of those, head over to the [Docker website](https://docs.docker.com/engine/install/) for instructions.

You will also need to create the following folders on the Docker host to store the database data:

```console
$ mkdir -p ${HOME}/sybase/data

$ mkdir -p ${HOME}/sybase/ase
```

It needs to be in `$HOME` to match the `docker-compose.yml` file definition.

Make sure `$HOME` has enough space. If not, you can symbolic link the `sybase` in your `$HOME` to some folder with more space:

```
$ ln -s $HOME/sybase /folder/with/plenty/of/space
```

# Build and Database Creation Instructions

The `Dockerfile` isn't enough to get you started. 

Building it only installs the ASE server binaries. You have to run the database creation *afterwards*. 

This two steps approach allows to have the database data outside the container itself.

1. Build the Docker image. The ASE installation in that build can take up to a dozen of minutes.

```console
$ docker build -t sybase/server:latest .
```

Alternatively, if you want to specify your fileserver from the command line instead of in the `Dockerfile`, run

```console
$ docker build --build-arg FILESERVER="http://whatever.com/" -t sybase/server:latest .
```

2. Run the image as **sybase** to create the database. Bind your host local folders as follow:

```
$ docker run --user=sybase \
    -v $HOME/sybase/data:/data \
    -v $HOME/sybase/ase:/home/sybase/ase \
    -it sybase/server:latest \
    bash
```

3. Run the database creation on the Docker image session. It is also a long process (up to a dozen of minutes):

```
$ create_dabatase.sh
```

This completes the database creation. Since the data are created in bound volumes, they will live even after your container stops. And they can also be migrated.

4. Create a *virtual network*. This enables attaching other devices to it afterwards and to assign a static IP to the container.

```
$ docker network create \
    --driver=bridge \
    --subnet=172.24.0.0/16 \
    --ip-range=172.24.1.0/24 \
    --gateway=172.24.1.254 \
    sybase-bridge
```

# Running it

Use **docker-compose** to start the Docker image.

The `docker-compose.yml` file attaches the container to a **sybase-bridge** virtual network created above. It also assigns it the static IP **172.24.1.1** for easier later reference. 

From the parent folder of the `docker-compose.yml` file, firing up the ASE server is as simple as :

```console
$ docker-compose up -d
```

To check that it runs, use `docker ps`:

```console
$ docker ps
CONTAINER ID   IMAGE                  COMMAND                  CREATED        STATUS         PORTS     NAMES
3ebf01013fef   sybase/server:latest   "/home/sybase/bin/en…"   11 hours ago   Up 2 seconds             sybase-ase-docker_ase-server_1
```

If you have proper clients installed, you can also try to open a database session. For example, using [FreeTDS](https://www.freetds.org)'s **fisql**:

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

This works because I have a **DB_TEST** entry in the `freetds.conf` file. See the [section on interface and freetds.conf files](#interface-or-freetdsconf-file)

To stop the container:

```console
$ docker stop 3ebf01013fef
```

Note that the ID is generated for every Docker session. You'll need to get it with `docker ps`.

# Technical Details

Feel free to change these in `ase.rs` in the `ressources` folder.

## Installation

- ASE installation folder: `/opt/sap`
- devices folder: `/data` on the container, mapped to `$HOME/sybase/data` on the host
- database installation folder: `/home/sybase/ase`

## Created Database

- Dataserver name: DB_TEST
- user: sa
- password: sybase

## Ressource Allocation
- Memory: 4GB
- CPUs: 2

## Charset

I left **iso_1** which comes by default, because I use that at work. But you may want to switch it to something more modern like **UTF-8**.

## Docker Image Size

The generated image's size is **557MB**. It's probably as small as it can get.

```console
$ docker image ls
REPOSITORY      TAG       IMAGE ID       CREATED         SIZE
sybase/server   latest    1415df5f6e03   7 minutes ago   557MB
ubuntu          focal     4dd97cefde62   3 days ago      72.9MB
```

This is *not* taking into account the **DB_TEST** database data in `sybase`

```console
$ du -Lksh $HOME/sybase
337M	/home/user/sybase
```

And we're talking about a brand new database here. It will only grow in size.

## Interface or freetds.conf file

Since the container has that static IP:

    172.24.1.1

You use the following `interface` file to connect to the database

```
DB_TEST
    master tcp ether 172.24.1.1 5000
    query tcp ether 172.24.1.1 5000
```

If you use [FreeTDS](https://www.freetds.org), the `interface` file will do too, but you can also add that entry to `freetds.conf`

```
[DB_TEST]
    host = 172.24.1.1
    port = 5000
    tds version = 5.0
```

Remember that this 172.24.1.1 is only visible from the virtual interface inside the Docker host or from any container attached to the virtual **sybase-bridge** network. To access **DB_TEST** from outside, you'll have to forward ports.
