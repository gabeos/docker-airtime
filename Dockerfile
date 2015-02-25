
FROM phusion/baseimage
MAINTAINER Gabriel Schubiner <gabriel.schubiner@gmail.com>

# Installations
RUN apt-get update  
RUN env DEBIAN_FRONTED="noninteractive" \
    apt-get install -y --no-install-recommends \
    apache2 \
    coreutils \
    libapache2-mod-php5 \
    libcamomile-ocaml-data \
    libzend-framework-php \
    lsb-release \
    lsof \
    odbc-postgresql \
    patch \
    php5 \
    php-apc \
    php5-curl \
    php-pear \
    python \
    pwgen \
    realpath \
    php5-pgsql

# Environment variables
## APC Configuration
ENV APC_ADMIN_USER apc
ENV APC_ADMIN_PASS changeme

## Turns off airtime cron script sending stats back tou sourcefabric.
ENV DISABLE_PHONE_HOME_STATS false

## DB Configuration
ENV DB_HOST localhost
ENV DB_USER airtime
ENV DB_PASS airtime
ENV DB_NAME airtime

## Rabbit MQ Configuration
ENV RABBITMQ_HOST 127.0.0.1
ENV RABBITMQ_PORT 5672
ENV RABBITMQ_USER admin
ENV RABBITMQ_PASSWORD changeme
ENV RABBITMQ_VHOST /airtime
ENV EXCHANGES "airtime-pypo|pypo-fetch|airtime-media-monitor|media-monitor"

## SSH
ENV DISABLE_SSH false

## PHP Configuration
ENV PHP_MEMORY_LIMIT 1024M
ENV PHP_MAX_EXECUTION_TIME 900

## Apache2 Configuration
RUN echo "www-data" >/etc/container_environment/APACHE_RUN_GROUP && \
    echo "www-data" >/etc/container_environment/APACHE_RUN_USER && \
    echo "/var/run/apache2/apache2.pid" >/etc/container_environment/APACHE_PID_FILE && \
    echo "/var/run/apache2" >/etc/container_environment/APACHE_RUN_DIR && \
    echo "/var/lock/apache2" >/etc/container_environment/APACHE_LOCK_DIR && \
    echo "/var/log/apache2" >/etc/container_environment/APACHE_LOG_DIR

# Airtime script-based install
RUN mkdir /airtime && \
    curl -L https://github.com/sourcefabric/Airtime/archive/airtime-2.5.2-rc1.tar.gz | tar xz -C /airtime --strip-components=1 

# Remove Postgres & RabbitMQ installation sections from install script
# Note: This is done through a somewhat complicated `sed` command, that
# creates incremental backups each time it is run, and moves the sections
# into a separate script called install_<arg1> in the same dir. 
# Adds shebang and necessary functions from install script so new script
# is executable.
ADD ./assets/scripts/breakout_section.sh /usr/bin/breakout_section
RUN chmod +x /usr/bin/breakout_section && \
    breakout_section postgres /airtime/install && \
    breakout_section rabbitmq /airtime/install 
   
# Stop service (re)start commands and run script without user input 
RUN sed -i \
    -e "s/service icecast2 start/#service icecast2 start/g" \
    -e "s/^loudCmd.*service apache2 rest.*\$/#&/g" \
    -e "s!/setup.py install!& --no-init-script!g" \
    -e "s/initctl reload/#&/g" \
    -e '/^for i in \//,/^done/ { s/.*/#&/g }' \
    /airtime/install

RUN chmod +x /airtime/install && \
    /airtime/install -ifa

# Add PHP environment update script
ADD ./assets/scripts/update_php_vars.sh /usr/bin/update_php_vars
RUN chmod +x /usr/bin/update_php_vars

# Volumes
VOLUME /data
VOLUME /usr/share/airtime
VOLUME /etc/airtime

# Ports
EXPOSE 22 80 443

# Services
ADD ./assets/services/apache.sh /etc/service/apache/run
ADD ./assets/services/apache-log-forwarder.sh /etc/service/apache-log-forwarder/run
RUN cp /airtime/python_apps/pypo/bin/airtime-liquidsoap /etc/service/airtime-liquidsoap/run && \
    cp /airtime/python_apps/pypo/bin/airtime-playout /etc/service/airtime-playout/run && \
    cp /airtime/python_apps/media-monitor/bin/airtime-media-monitor /etc/service/airtime-media-monitor/run

RUN chmod -R +x /etc/service/

# Init script
CMD ["/sbin/my_init"]

ADD ./assets/init.sh /etc/my_init.d/10_init.sh
RUN chmod -R +x /etc/my_init.d/

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
