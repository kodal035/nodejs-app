#!/bin/bash
if [ -d /tmp/nodejs-app ]; then
  rm -rf /tmp/nodejs-app
fi
git clone https://github.com/kodal035/nodejs-app.git /tmp/nodejs-app
cp /tmp/nodejs-app/scripts/* /usr/local/bin/
chmod +x /usr/local/bin/*.sh
