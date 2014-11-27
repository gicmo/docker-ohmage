#!/bin/bash
if [ -f /setup.sh ]; then
  /setup.sh
  rm /setup.sh
fi

# start all the services
/usr/local/bin/supervisord -n
