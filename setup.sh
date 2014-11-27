#!/bin/bash
#mysql has to be started this way as it doesn't work to call from /etc/init.d

/usr/bin/mysqld_safe & 
sleep 10s

OHMAGE_USER='ohmage'
OHMAGE_PASS='&!sickly'
OHMAGE_DB='ohmage'

# Here we generate random passwords (thank you pwgen!).
MYSQL_PASSWORD=`pwgen -c -n -1 12`

#This is so the passwords show up in logs. 
echo mysql root password: $MYSQL_PASSWORD
echo $MYSQL_PASSWORD > /mysql-root-pw.txt

mysqladmin -u root password $MYSQL_PASSWORD
mysql -uroot -p$MYSQL_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQL_PASSWORD' WITH GRANT OPTION;"
mysql -uroot -p$MYSQL_PASSWORD -e "FLUSH PRIVILEGES;"

mysql -uroot -p$MYSQL_PASSWORD < /tmp/sql/base/ohmage-ddl.sql

for sql_file in `ls /tmp/sql/settings/*.sql`; do mysql -uroot -p$MYSQL_PASSWORD $OHMAGE_DB < "$sql_file"; done

mysql -uroot -p$MYSQL_PASSWORD $OHMAGE_DB < /tmp/sql/preferences/default_preferences.sql
mysql -uroot -p$MYSQL_PASSWORD -e "CREATE USER '$OHMAGE_USER'@'%' IDENTIFIED BY '$OHMAGE_PASS';"
mysql -uroot -p$MYSQL_PASSWORD -e "GRANT ALL PRIVILEGES ON $OHMAGE_DB.* TO '$OHMAGE_USER'@'%' IDENTIFIED BY '$OHMAGE_PASS' WITH GRANT OPTION;"
mysql -uroot -p$MYSQL_PASSWORD -e "FLUSH PRIVILEGES;"

killall mysqld
