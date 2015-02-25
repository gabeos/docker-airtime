
FROM phusion/baseimage
MAINTAINER Gabriel Schubiner <gabriel.schubiner@gmail.com>

# Add Sourcefabric keys and apt repository
RUN curl http://yum.sourcefabric.org/RPM-GPG-KEY | gpg --import - && \
    gpg -a --export 174C1854 | apt-key add -
ADD ./assets/airtime.sources.list /etc/apt/sources.list.d/airtime.sources.list
    
# Installations
RUN apt-get update  
RUN env DEBIAN_FRONTED="noninteractive" \
    apt-get install -y --no-install-recommends python-virtualenv 

# Environment variables
## APC Configuration
ENV APC_ADMIN_USER apc
ENV APC_ADMIN_PASS changeme
ENV APC_ADMIN_PAGE_ENABLE true

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

# Remove Postgres installation from install script
# Remove RabbitMQ installation from install script
    
RUN sed -i \
    -e "s/service icecast2 start/#service icecast2 start/g" \
    -e "s/^\(loudCmd .*apt-get.*install.*\)postgresql\(.*\)$/\1 \2/g" \
    -e "/^loudCmd.*apt-get.*rabbitmq-server/loudCmd.*rabbitmqctl.*$/d" \
    -e "s/^loudCmd.*service apache2 rest.*$/#&/g" \
    /airtime/install

RUN chmod +x /airtime/install && \
    /airtime/install

# PHP Setup
ADD ./assets/update_php_vars.sh /usr/bin/update_php_vars.sh
RUN chmod +x /usr/bin/update_php_vars.sh && update_php_vars.sh

# Volumes
VOLUME /data
VOLUME /usr/share/airtime
VOLUME /etc/airtime

# Ports
EXPOSE 22 80 443

# Services
ADD ./assets/services/apache.sh /etc/service/apache/run
ADD ./assets/services/apache-log-forwarder.sh /etc/service/apache-log-forwarder/run
RUN chmod -R +x /etc/service/

# Init script
CMD ["/sbin/my_init"]

ADD ./assets/init.sh /etc/my_init.d/10_init.sh
RUN chmod -R +x /etc/my_init.d/

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
