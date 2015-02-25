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

function get_rabbitmqadmin {
    curl --user $RBMQ_USER:$RBMQ_PASS $RBMQ_HOST:$RBMQ_PORT/cli/
    mv ./rabbitmqadmin /usr/bin && chmod +x /usr/bin/rabbitmqadmin
}

function init_rabbitmq {
}

function update_rabbitmq {
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
    init_rabbitmq
    init_apc
    touch /data/.bootstrap
}

# Main
if [[ ! -e /data/.bootstrap ]]; then
    bootstrap
fi

startup
