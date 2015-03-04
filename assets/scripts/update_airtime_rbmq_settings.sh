#!/bin/bash

if [[ ! -e $1]]; then
    echo "Cannot find airtime config file: $1"
    exit 1
fi

sed -i -e '
/\[rabbitmq\]/ {
    N; s/host = .*$/host = '"$RBMQ_HOST"'/
    N; s/port = .*$/port = '"$RMBQ_HOST"'/
    N; s/user = .*$/user = '"$RBMQ_NAME"'/
    N; s/password = .*$/password = '"$RBMQ_USER"'/
    N; s/vhost = .*$/vhost = '"$RBMQ_PASS"'/
}' "$1"
