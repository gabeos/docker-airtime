#!/bin/bash

# DB
# Postgres-only
#  $dbuser = $CC_CONFIG['dsn']['username']
# ..[password] , ['database'] , ['hostspec']

. deactivation.sh

function update_ssh_keys {

    # If there are keys present in /data/ssh VOLUME, copy them to the right place
    if [[ -d /data/ssh ]]; then
        echo "Initializing SSH authorized_keys for root"
        shopt -s nullglob
        for key in /data/ssh/*.pub; do
            echo "Adding $key to root authorized_keys file"
            (cat "$key"; echo) >> /root/.ssh/authorized_keys
        done
    else
        echo "No new ssh keys found."
    fi
}

function check_ssh {
    echo "Checking SSH."
    if [[ $DISABLE_SSH == false ]]; then 
        echo "Enabling SSH"
        rm -f /etc/service/ssh/down
    else
        touch /etc/service/ssh/down
    fi
}

function update_cron {
    if [[ "$DISABLE_PHONE_HOME_STATS" == "true" ]]; then
        sed -i -e 's!^.*phone_home_stat.*$!#&!g' /etc/cron.d/airtime-crons
    else
        sed -i -e 's!^#\(.*phone_home_stat.*\)$!\1!g' /etc/cron.d/airtime-crons
    fi
}

function init_postgres {
    if [[ -n $POSTGRES_PORT_5432_TCP_ADDR ]]; then
        DB_HOST=${DB_HOST:-${POSTGRES_PORT_5432_TCP_ADDR}}
        DB_PORT=${DB_PORT:-${POSTGRES_PORT_5432_TCP_PORT}}
	    DB_PASS=${DB_PASS:-${POSTGRES_ENV_POSTGRES_PASSWORD}}
	    DB_USER=${DB_USER:-${POSTGRES_ENV_POSTGRES_USER}}
    elif [[ -x ${DB_PORT} ]] || [[ -z ${DB_HOST+x} ]] || [[ -z ${DB_USER+x} ]] || [[ -z ${DB_PASS+x} ]]; then
        echo "Error: DB must be alias'ed correctly, or all DB parameters must be specified."
        exit 1
    fi
    # TODO: sed vars into airtime cfg
    # [database]
    # host = xxxx
    # dbuser = 
    # dbname = 
    # dbpass = 
}

function get_rabbitmqadmin {
    curl -o /usr/bin/rabbitmqadmin --user $RABBITMQ_USER:$RABBITMQ_PASS http://$RABBITMQ_HOST:$RABBITMQ_PORT/cli/rabbitmqadmin
    chmod +x /usr/bin/rabbitmqadmin
}

# Ensure environment variables are kept
function write_rabbitmq_env {
    echo "$RABBITMQ_VHOST" >/etc/container_environment/RABBITMQ_VHOST
    echo "$RABBITMQ_USER" >/etc/container_environment/RABBITMQ_USER
    echo "$RABBITMQ_PASSWORD" >/etc/container_environment/RABBITMQ_PASSWORD
    echo "$RABBITMQ_EXCHANGES" >/etc/container_environment/RABBITMQ_EXCHANGES
}

function update_rabbitmqadmin_config {
#TODO
}

function extract_rabbitmq_env_info {
    if [[ -z $RABBITMQ_PORT_15672_TCP ]]; then
        export RABBITMQ_USER=${RABBITMQ_ENV_RABBITMQ_USER:-"airtime"}
        export RABBITMQ_PASSWORD=${RABBITMQ_ENV_RABBITMQ_PASSWORD:-"airtime"}
        export RABBITMQ_HOST=${RABBITMQ_PORT_15672_PORT_TCP_ADDR:-"rabbitmq"}
    fi
    write_rabbitmq_env
}

function init_rabbitmq {
    export RABBITMQ_VHOST=${RABBITMQ_VHOST:-"/airtime"}
    export RABBITMQ_USER=${RABBITMQ_USER:-"airtime"}
    export RABBITMQ_PASSWORD=${RABBITMQ_PASSWORD:-"airtime"}
    export RABBITMQ_EXCHANGES="airtime-pypo|pypo-fetch|airtime-media-monitor|media-monitor"
    
    write_rabbitmq_env
    update_rabbitmqadmin_config
    get_rabbitmqadmin

    # Ignore errors in this check to avoid dying when vhost isn't found
    set +e
    rabbitmqadmin list vhosts | grep -w ${RABBITMQ_VHOST} > /dev/null
    RESULT="$?"
    set -e

    # Only run these if the vhost doesn't exist
    if [ "$RESULT" != "0" ]; then
        echo "\n * Creating RabbitMQ user ${RABBITMQ_USER}..."

        rabbitmqctl add_vhost ${RABBITMQ_VHOST}
        rabbitmqctl add_user ${RABBITMQ_USER} ${RABBITMQ_PASSWORD}
    else
        echo "\nRabbitMQ user already exists, skipping creation"
    fi

    echo "\n * Setting RabbitMQ user permissions..."
    rabbitmqctl set_permissions -p ${RABBITMQ_VHOST} ${RABBITMQ_USER} "$EXCHANGES" "$EXCHANGES" "$EXCHANGES"
}

function update_rabbitmq {
    update_rabbitmqadmin_config
# TODO 
}

function init_apc {
    gzip -d /usr/share/doc/php-apc/apc.php.gz 
    cp /usr/share/doc/php-apc/apc.php /usr/share/airtime/public/
}

function update_apc {
    if [[ "$APC_ADMIN_PAGE_ENABLE" == true ]]; then
        activate apc.php
        sed -i \
            -e "s!^\(defaults.*ADMIN_USERNAME','\).*?\('.*\)$!\1$APC_ADMIN_USER\2!g" \
            -e "s!^\(defaults.*ADMIN_PASSWORD','\).*?\(\.*\)$!\1$APC_ADMIN_PASS\2!g" \
            /usr/share/airtime/public/apc.php
    else
        deactivate /usr/share/airtime/public/apc.php
    fi
}

function startup {
    update_ssh_keys
    check_ssh
    update_rabbitmq
    update_cron
    update_apc

    #update_liquidsoap
    #update_icecast
    #update_airtime
}

function bootstrap {
    init_postgres
    init_rabbitmq
    init_apc
    touch /data/.bootstrap
}

# Main
if [[ ! -e /data/.bootstrap ]]; then
    bootstrap
fi

startup
