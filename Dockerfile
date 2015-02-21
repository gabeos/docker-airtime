
FROM hollowearthradio/baseimage-12.04
MAINTAINER Gabriel Schubiner <gabriel.schubiner@gmail.com>

# Installations
RUN apt-get update && apt-get install -y --no-install-recommends \
    apache2 \
    libapache2-mod-php5 \
    php5 \
    php5-cli \
    php-apc \
    php5-gd \
    rabbitmq-server

RUN mkdir /airtime && \
    curl https://github.com/sourcefabric/Airtime/archive/airtime-2.5.1-ga.tar.gz | tar xz -C /airtime --strip-components=1 

RUN chmod +x /airtime/install_full/ubuntu/airtime-full-install && \
    /airtime/install_full/ubuntu/airtime-full-install

# Install APC admin page
# RUN cp /usr/share/doc/php-apc/apc.php /usr/share/airtime/public/
# TODO Set password -- line 42 of apc.php

# Not needed, Airtime manual recommends for desktop install
# RUN apt-get purge -y pulseaudio ubuntu-sounds

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


