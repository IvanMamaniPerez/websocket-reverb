FROM alpine:3.20

# This arguments should be sync with the PHP version you want to use
ARG PHP_VERSION_USE_APK=83
ARG PHP_VERSION=8.3
ARG PROJECT_NAME="erp_fullstack"

WORKDIR /var/www

# Essentials
RUN echo "UTC" > /etc/timezone
RUN apk add --no-cache zip unzip curl sqlite nginx supervisor

# Installing bash
RUN apk add --no-cache bash 
RUN sed -i 's/bin\/ash/bin\/bash/g' /etc/passwd

# Installing PHP
RUN apk add --no-cache php${PHP_VERSION_USE_APK} \
    php${PHP_VERSION_USE_APK}-common \
    php${PHP_VERSION_USE_APK}-fpm \
    php${PHP_VERSION_USE_APK}-pdo \
    php${PHP_VERSION_USE_APK}-opcache \
    php${PHP_VERSION_USE_APK}-zip \
    php${PHP_VERSION_USE_APK}-phar \
    php${PHP_VERSION_USE_APK}-iconv \
    php${PHP_VERSION_USE_APK}-cli \
    php${PHP_VERSION_USE_APK}-curl \
    php${PHP_VERSION_USE_APK}-openssl \
    php${PHP_VERSION_USE_APK}-mbstring \
    php${PHP_VERSION_USE_APK}-tokenizer \
    php${PHP_VERSION_USE_APK}-fileinfo \
    php${PHP_VERSION_USE_APK}-json \
    php${PHP_VERSION_USE_APK}-xml \
    php${PHP_VERSION_USE_APK}-xmlwriter \
    php${PHP_VERSION_USE_APK}-simplexml \
    php${PHP_VERSION_USE_APK}-dom \
    php${PHP_VERSION_USE_APK}-pdo_mysql \
    php${PHP_VERSION_USE_APK}-pdo_pgsql \
    php${PHP_VERSION_USE_APK}-pdo_sqlite \
    php${PHP_VERSION_USE_APK}-tokenizer \
    php${PHP_VERSION_USE_APK}-posix \
    php${PHP_VERSION_USE_APK}-pecl-redis \
    php${PHP_VERSION_USE_APK}-pecl-swoole \
    php${PHP_VERSION_USE_APK}-pcntl \
    php${PHP_VERSION_USE_APK}-gd

RUN rm -f /usr/bin/php && ln -s /usr/bin/php${PHP_VERSION_USE_APK} /usr/bin/php

# Installing composer
RUN curl -sS https://getcomposer.org/installer -o composer-setup.php
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer
RUN rm -rf composer-setup.php

# Installing Node.js and npm
RUN apk add --no-cache nodejs npm


# Configure supervisor
RUN mkdir -p /etc/supervisor.d/
COPY .docker/supervisord.ini /etc/supervisor.d/supervisord.ini


# Configure nginx
# Delete the default server definition
RUN rm /etc/nginx/http.d/default.conf
COPY .docker/nginx.conf /etc/nginx/
COPY .docker/nginx-laravel.conf /etc/nginx/modules/


RUN mkdir -p /var/lib/nginx/tmp/client_body/ && \
    chown -R nobody:nogroup /var/lib/nginx/ && \
    chmod -R 777 /var/lib/nginx/
RUN mkdir -p /run/nginx/ && \
    touch /run/nginx/nginx.pid

RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

RUN mkdir -p /var/log/supervisor/
RUN touch /var/log/supervisor/laravel-octane.log
RUN touch /var/log/supervisor/laravel-inertia_ssr.log
RUN touch /var/log/supervisor/nginx-custom.log

# Sure the nginx-laravel-error.log file exists
RUN touch /var/log/nginx/nginx-laravel-error.log


# Building process
COPY . .

# RUN composer install # Se esta ejecutando en el supervisord.conf 
RUN npm install && composer install


# Set permissions on the /var/www/public directory
RUN chmod -R 755 /var/www/public && \
    chown -R nobody:nobody /var/www/public && \
    chown -R nobody:nobody /var/www/storage

EXPOSE 80 443 5173

CMD ["supervisord", "-c", "/etc/supervisor.d/supervisord.ini"]