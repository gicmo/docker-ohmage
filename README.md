docker-ohmage
=============

[ohmage server](https://github.com/ohmage/server) in a docker container

Following components need to be added before building:
* sql.zip
* webapp-ohmage-2.16-no_ssl.war

sql.zip is the sql folder from the ohmage-server repository zipped,
and webapp-ohmage-2.16-no_ssl.war is the compiled webapp.

Building...
```shell
docker build -t='ohmage-docker' .
```

Running...
```shell
docker run -p 8080:8080 --name ohmage-docker -d ohmage-docker
docker start ohmage-docker
```

Afterwards you should be able to connect to port 8080 of the 
machine that is running docker.
