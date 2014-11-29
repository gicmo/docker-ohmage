docker-ohmage
=============

[ohmage server](https://github.com/ohmage/server) in a docker container
NB: This is for the 3.0 branch of ohmage server. Use the ohamge-2.0 for 2.X.

Following components need to be added before building:
* mongo.zip
* ohmage.war


mongo.zip is the dev-setup/mongo folder from the ohmage-server repository 
zipped, and ohmage.war is the compiled server webapp ('dist' ant target)

Building...
```shell
docker build -t='ohmage-docker' .
```

Running...
```shell
docker run -p 80:80 --name ohmage-docker -d ohmage-docker
docker start ohmage-docker
```

Afterwards you should be able to connect via http to the 
machine that is running docker. For docker running on
on the same host the url would be:
http://localhost/ohmage


