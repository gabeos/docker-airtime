
FROM phusion/baseimage:latest
MAINTAINER Gabriel Schubiner <gabriel.schubiner@gmail.com>

# Installations
RUN apt-get update  
RUN env DEBIAN_FRONTED="noninteractive" \
    apt-get install -y --no-install-recommends \
    apache2 \
    coreutils \
    git \
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
    php5-pgsql \
    python \
    pwgen \
    realpath 

# Environment variables
## APC Configuration
#ENV APC_ADMIN_USER apc
#ENV APC_ADMIN_PASS changeme

## Turns off airtime cron script sending stats back tou sourcefabric.
#ENV DISABLE_PHONE_HOME_STATS false

## DB Configuration
#ENV DB_HOST localhost
#ENV DB_USER airtime
#ENV DB_PASS airtime
#ENV DB_NAME airtime

## Rabbit MQ Configuration
#ENV RABBITMQ_HOST 127.0.0.1
#ENV RABBITMQ_PORT 5672
#ENV RABBITMQ_USER admin
#ENV RABBITMQ_PASSWORD changeme
#ENV RABBITMQ_VHOST /airtime
#ENV EXCHANGES "airtime-pypo|pypo-fetch|airtime-media-monitor|media-monitor"

## SSH
#ENV DISABLE_SSH false

## PHP Configuration
#ENV PHP_MEMORY_LIMIT 1024M
#ENV PHP_MAX_EXECUTION_TIME 900

# My scripts
ADD ./assets/scripts/breakout_section.sh /usr/bin/breakout_airtime_install_section
RUN chmod +x /usr/bin/breakout_airtime_install_section

# Airtime script-based install
RUN cd /usr/share/ && \
    git clone https://github.com/sourcefabric/Airtime --branch=2.5.x-installer-monitless --depth=1 && cd /

RUN breakout_airtime_install_section postgres /usr/share/Airtime/install && \
    breakout_airtime_install_section rabbitmq /usr/share/Airtime/install
RUN /usr/share/Airtime/install -ifapdIv

# Services
ADD ./assets/services/icecast2 /etc/service/icecast2/run
#ADD ./assets/services/airtime-playout /etc/service/airtime-playout/run
#ADD ./assets/services/airtime-media-monitor /etc/service/airtime-media-monitor/run
ADD ./assets/services/dbus /etc/service/dbus/run
ADD ./assets/services/pulseaudio /etc/service/pulseaudio/run
RUN cp /usr/share/Airtime/python_apps/pypo/bin/airtime-liquidsoap /etc/service/airtime-liquidsoap/run
RUN cp /usr/share/Airtime/python_apps/pypo/bin/airtime-playout /etc/service/airtime-playout/run
RUN cp /usr/share/Airtime/python_apps/media-monitor/bin/airtime-media-monitor /etc/service/airtime-media-monitor/run
#ADD ./assets/services/airtime-liquidsoap /etc/service/airtime-liquidsoap/run
ADD ./assets/services/apache /etc/service/apache/run
ADD ./assets/services/apache-log-forwarder /etc/service/apache-log-forwarder/run
RUN chmod -R +x /etc/service/*

# Init
ADD ./assets/init.sh /etc/my_init.d/10_init.sh

# Volumes
VOLUME /data
VOLUME /usr/share/airtime
VOLUME /etc/airtime

# Ports
EXPOSE 22 80 443

# Init script
CMD ["/sbin/init"]

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
