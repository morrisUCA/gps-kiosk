#!/bin/sh

CONFIG_DIR="/home/node/.signalk"
if [ -z "$(ls -A $CONFIG_DIR)" ]; then
  echo "📦 Volume is empty — pulling default config from GitHub..."
  git clone https://github.com/your/repo.git /tmp/config
  cp -a /tmp/config/* "$CONFIG_DIR"
fi

exec /usr/local/bin/signalk-server
