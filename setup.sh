#!/bin/bash

# restore mongodb
gosu mongodb /usr/local/bin/mongod &
sleep 4s
gosu mongodb mongorestore /tmp/mongo/ohmage
mongod --shutdown
