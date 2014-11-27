FROM java:7-jre

# base on tomcat from docker
MAINTAINER Christian Kellner kellner@bio.lmu.de

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get -y upgrade

# Basic Requirements
RUN apt-get -y install mysql-server mysql-client curl git unzip python-setuptools pwgen

### expose mysql to the world
RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/my.cnf

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

chown tomcat:tomcat -R /opt/ohmage/
ADD ./webapp-ohmage-2.16-no_ssl.war /usr/local/tomcat/webapps/app.war
chown tomcat:tocat -R /usr/local/tomcat/
ADD ./sql.zip /tmp/sql.zip

WORKDIR /tmp
RUN unzip /tmp/sql.zip

### finally ...
ADD ./start.sh /start.sh
RUN chmod 755 /start.sh

ADD ./setup.sh /setup.sh
RUN chmod 755 /setup.sh

WORKDIR /
EXPOSE 3306
EXPOSE 8080

CMD ["/bin/bash", "/start.sh"]
