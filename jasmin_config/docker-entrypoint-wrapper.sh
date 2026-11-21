#!/bin/bash
set -e

CONFIG_PATH=${CONFIG_PATH:-/etc/jasmin}

# If jasmin.cfg is mounted from host, copy it to a writable location first
if [ -f /mnt/jasmin.cfg ]; then
    cp /mnt/jasmin.cfg ${CONFIG_PATH}/jasmin.cfg
fi

# Change binding host:port for redis, and amqp
if [ -n "$REDIS_CLIENT_HOST" ]; then
    sed -i "/\[redis-client\]/,/host=/  s/host=.*/host=$REDIS_CLIENT_HOST/" ${CONFIG_PATH}/jasmin.cfg
fi

if [ -n "$REDIS_CLIENT_PORT" ]; then
    sed -i "/\[redis-client\]/,/port=/  s/port=.*/port=$REDIS_CLIENT_PORT/" ${CONFIG_PATH}/jasmin.cfg
fi

if [ -n "$AMQP_BROKER_HOST" ]; then
    sed -i "/\[amqp-broker\]/,/host=/  s/host=.*/host=$AMQP_BROKER_HOST/" ${CONFIG_PATH}/jasmin.cfg
fi

if [ -n "$AMQP_BROKER_PORT" ]; then
    sed -i "/\[amqp-broker\]/,/port=/  s/port=.*/port=$AMQP_BROKER_PORT/" ${CONFIG_PATH}/jasmin.cfg
fi

echo 'Cleaning lock files'
rm -f /tmp/*.lock

# Handle interceptor if needed
if [ "$2" = "--enable-interceptor-client" ] || echo "$@" | grep -q "interceptor"; then
  echo 'Starting interceptord'
  interceptord.py &
fi

# Execute the command directly (don't call original entrypoint to avoid duplicate sed operations)
# If no command provided, use the default
if [ $# -eq 0 ]; then
    exec jasmind.py --enable-interceptor-client --enable-dlr-thrower --enable-dlr-lookup -u jcliadmin -p jclipwd
else
    exec "$@"
fi

