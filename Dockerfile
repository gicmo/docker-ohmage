FROM java:7-jre

# base on tomcat from docker
MAINTAINER Christian Kellner kellner@bio.lmu.de

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get -y upgrade

# Basic Requirements
RUN apt-get -y install curl git unzip python-setuptools pwgen python-bcrypt nginx

### Tomcat
# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r tomcat && useradd -r --create-home -g tomcat tomcat

ENV CATALINA_HOME /usr/local/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
RUN mkdir -p "$CATALINA_HOME" && chown tomcat:tomcat "$CATALINA_HOME"
WORKDIR $CATALINA_HOME
USER tomcat

# see https://www.apache.org/dist/tomcat/tomcat-8/KEYS
RUN gpg --keyserver pgp.mit.edu --recv-keys \
  05AB33110949707C93A279E3D3EFE6B686867BA6 \
  07E48665A34DCAFAE522E5E6266191C37C037D42 \
  47309207D818FFD8DCD3F83F1931D684307A10A5 \
  541FBE7D8F78B25E055DDEE13C370389288584E7 \
  61B832AC2F1C5A90F0F9B00A1C506407564C17A3 \
  713DA88BE50911535FE716F5208B0AB1D63011C7 \
  79F7026C690BAA50B92CD8B66A3AD3F4F22C4FED \
  9BA44C2621385CB966EBA586F72C284D731FABEE \
  A27677289986DB50844682F8ACB77FC2E86E29AC \
  A9C5DF4D22E99998D9875A5110C01C5A2F6059E7 \
  DCFD35E0BF8CA7344752DE8B6FB21E8933C60243 \
  F3A04C595DB5B6A5F1ECA43E3B7BBB100D811BBE \
  F7DA48BB64BCB84ECBA7EE6935CD23C10D498E23

ENV TOMCAT_MAJOR 7
ENV TOMCAT_VERSION 7.0.57
ENV TOMCAT_TGZ_URL https://www.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz

RUN curl -SL "$TOMCAT_TGZ_URL" -o tomcat.tar.gz \
  && curl -SL "$TOMCAT_TGZ_URL.asc" -o tomcat.tar.gz.asc \
  && gpg --verify tomcat.tar.gz.asc \
  && tar -xvf tomcat.tar.gz --strip-components=1 \
  && rm bin/*.bat \
  && rm tomcat.tar.gz*


USER root
RUN rm /usr/local/tomcat/conf/tomcat-users.xml
ADD ./tomcat-users.xml /usr/local/tomcat/conf/tomcat-users.xml
RUN chmod 600 /usr/local/tomcat/conf/tomcat-users.xml
RUN chown tomcat:tomcat /usr/local/tomcat/conf/tomcat-users.xml

ADD ./tomcat_sd.sh /usr/local/tomcat/bin/tomcat_sd.sh
RUN chmod 755 /usr/local/tomcat/bin/tomcat_sd.sh

ADD ./tomcat.jmx.pwd /etc/tomcat.jmx.pwd
ADD ./tomcat.jmxremote.access /etc/tomcat.jmxremote.access
RUN chmod 600 /etc/tomcat.jmx.pwd
RUN chmod 600 /etc/tomcat.jmxremote.access
RUN chown tomcat:tomcat /etc/tomcat.jmx.pwd
RUN chown tomcat:tomcat /etc/tomcat.jmxremote.access


### mongo
RUN groupadd -r mongodb && useradd -r -g mongodb mongodb
RUN gpg --keyserver pgp.mit.edu --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4

RUN curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture)" \
  && curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture).asc" \
  && gpg --verify /usr/local/bin/gosu.asc \
  && rm /usr/local/bin/gosu.asc \
  && chmod +x /usr/local/bin/gosu

ENV MONGO_RELEASE_FINGERPRINT DFFA3DCF326E302C4787673A01C4E7FAAAB2461C
RUN gpg --keyserver pgp.mit.edu --recv-keys $MONGO_RELEASE_FINGERPRINT

ENV MONGO_VERSION 2.6.5

RUN curl -SL "https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-$MONGO_VERSION.tgz" -o mongo.tgz \
  && curl -SL "https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-$MONGO_VERSION.tgz.sig" -o mongo.tgz.sig \
  && gpg --verify mongo.tgz.sig \
  && tar -xvf mongo.tgz -C /usr/local --strip-components=1 \
  && rm mongo.tgz*

# This should be done in the future
# VOLUME /data/db
RUN mkdir -p /data/db
RUN chown -R mongodb /data/db


### gosu helper
RUN gpg --keyserver pgp.mit.edu --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture)" \
  && curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture).asc" \
  && gpg --verify /usr/local/bin/gosu.asc \
  && rm /usr/local/bin/gosu.asc \
  && chmod +x /usr/local/bin/gosu

### supervisord
RUN /usr/bin/easy_install supervisor
RUN /usr/bin/easy_install supervisor-stdout
ADD ./supervisord.conf /etc/supervisord.conf

### ohmage
RUN mkdir -p /opt/ohmage/userdata/images/
RUN mkdir /opt/ohmage/userdata/documents
RUN mkdir /opt/ohmage/userdata/audio/
RUN mkdir /opt/ohmage/userdata/video/
RUN mkdir -p /opt/ohmage/logs/audits/
RUN chown tomcat:tomcat -R /opt/ohmage/
RUN chown tomcat:tomcat -R /usr/local/tomcat/

ADD ./ohmage.ngnix.conf /etc/nginx/sites-available/default
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
RUN mkdir -p /var/www/ohmage
RUN chown -R www-data:www-data /var/www/ohmage

ADD ./mongo.zip /tmp/mongo.zip 

WORKDIR /tmp
RUN unzip /tmp/mongo.zip
RUN chown mongodb:mongodb -R /tmp/mongo

### finally ...
ADD ./start.sh /start.sh
RUN chmod 755 /start.sh

ADD ./setup.sh /setup.sh
RUN chmod 755 /setup.sh

# deploy the ohmage webapp
RUN mkdir /var/log/ohmage
RUN chown tomcat:tomcat /var/log/ohmage
RUN mkdir /etc/ohmage
ADD ./log4j2.xml /etc/ohmage/log4j2.xml
ADD ./ohmage.conf /etc/ohmage.conf

ADD ./ohmage.war /usr/local/tomcat/webapps/ohmage.war
RUN chown tomcat:tomcat -R /usr/local/tomcat/webapps

WORKDIR /
EXPOSE 3306
EXPOSE 8080
EXPOSE 80

CMD ["/bin/bash", "/start.sh"]
