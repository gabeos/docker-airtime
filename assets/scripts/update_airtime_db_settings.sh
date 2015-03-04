#!/bin/bash

if [[ ! -e $1]]; then
    echo "Cannot find airtime config file: $1"
    exit 1
fi

sed -i -e '
/\[database\]/ {
    N; s/host = .*$/host = '"$DB_HOST"'/
    N; s/dbname = .*$/dbname = '"$DB_NAME"'/
    N; s/dbuser = .*$/dbuser = '"$DB_USER"'/
    N; s/dbpass = .*$/dbpass  = '"$DB_PASS"'/
}' "$1"
