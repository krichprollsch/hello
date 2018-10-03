FROM php:7.2-fpm-alpine
MAINTAINER Pierre Tachoire <pierre@tch.re>

# ensure opcache is installed
RUN docker-php-ext-install opcache

RUN wget https://raw.githubusercontent.com/composer/getcomposer.org/1b137f8bf6db3e79a38a5bc45324414a6b1f9df2/web/installer -O - -q | php -- --quiet \
    && mv composer.phar /usr/bin/composer

# copy the configuration for fpm/php
COPY docker/app/opcache.ini /usr/local/etc/php/conf.d/opcache.ini
COPY docker/app/fpm.conf /etc/supervisor/conf.d/fpm.conf

WORKDIR /srv

# copy the symfony app
COPY . ./

ENV APP_ENV=prod
RUN composer install --no-interaction --no-progress --optimize-autoloader --no-dev
RUN php bin/console cache:warmup --env=prod
