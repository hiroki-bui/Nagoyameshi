
FROM php:8.2-fpm

WORKDIR /app

RUN apt-get update \
    && apt-get install -y \
    git \
    zip \
    unzip \
    vim \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng-dev \
    libfontconfig1 \
    libxrender1

RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install gd
RUN docker-php-ext-install bcmath
RUN docker-php-ext-install pdo_mysql mysqli exif

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_HOME /composer

COPY php.ini /usr/local/etc/php/php.ini
COPY laravel-nagoyameshi/ /app

RUN composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader

CMD ["php", "./artisan", "serve", "--host", "0.0.0.0", "--port=80"]
