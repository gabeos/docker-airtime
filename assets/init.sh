#!/bin/bash

# DB
# Postgres-only
#  $dbuser = $CC_CONFIG['dsn']['username']
# ..[password] , ['database'] , ['hostspec']

function init_ssh_keys {

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

function update_rabbitmq_settings {
# TODO 
}

function init_apc {
    gzip -d /usr/share/doc/php-apc/apc.php.gz 
    cp /usr/share/doc/php-apc/apc.php /usr/share/airtime/public/
}

function update_apc_settings {
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

function install_airtime {
    ./airtime/install_minimal/airtime_install
}

function bootstrap {
    get_rabbitmqadmin
    install_airtime
    update_cron
    update_apc_settings
}

. deactivation.sh

if [[ -e /data/.bootstrap ]]; then
    start
else
    bootstrap
fi
