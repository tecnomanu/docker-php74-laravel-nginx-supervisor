FROM php:7.4.26-fpm-alpine

RUN apk update && apk upgrade

# Essentials
RUN echo "UTC" > /etc/timezone
RUN apk add --no-cache zip unzip curl sqlite nginx supervisor

RUN apk add libzip-dev nodejs npm
RUN apk add php7-cgi php7-bcmath php7-gd php7-mysqli php7-zlib php7-curl php7-zip gmp-dev libzip-dev

RUN apk --no-cache add php7-mbstring php7-iconv

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql zip exif gmp

# fix work iconv library with alphine
RUN apk add gnu-libiconv=1.15-r3 --update-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.13/community/ --allow-untrusted
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so

# Install GD Extension
RUN apk add --no-cache libpng libpng-dev && docker-php-ext-install gd && apk del libpng-dev

# Installing bash
RUN apk add bash
RUN sed -i 's/bin\/ash/bin\/bash/g' /etc/passwd

# Installing composer
RUN curl -sS https://getcomposer.org/installer -o composer-setup.php
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer
RUN rm -rf composer-setup.php

# Configure supervisor
RUN mkdir -p /etc/supervisor.d/
RUN touch /run/supervisord.sock
COPY ./docker-compose/supervisord/supervisord.ini /etc/supervisor.d/supervisord.ini

# Cron Config
COPY ./docker-compose/crontab /etc/crontabs/root

# Config PHP
COPY ./docker-compose/php/local.ini /usr/local/etc/php/php.ini

# Nginx configuration
RUN mkdir -p /run/nginx/
RUN touch /run/nginx/nginx.pid

COPY ./docker-compose/nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./docker-compose/nginx/conf.d/app.conf /etc/nginx/http.d/default.conf
#/etc/nginx/modules

RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

USER root
WORKDIR /var/www

EXPOSE 80

CMD ['supervisord', '-c', '/etc/supervisor.d/supervisord.ini']
