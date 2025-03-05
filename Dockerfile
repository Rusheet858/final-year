# Base PHP image
FROM php:8.3-fpm-alpine AS base

# Install required dependencies
RUN apk --update add mysql-client curl git libxml2-dev libzip-dev zip nodejs npm \
    && docker-php-ext-install pdo_mysql zip xml

ENV COMPOSER_HOME ./.composer
COPY --from=composer:2.7.7 /usr/bin/composer /usr/bin/composer

FROM base AS deps
WORKDIR /var/www/html

COPY composer.json composer.lock ./
RUN composer install --no-dev --no-autoloader --no-scripts


FROM node:18-alpine AS frontend
WORKDIR /app


COPY package.json package-lock.json ./
RUN npm install


COPY . .
RUN npm run build


FROM base AS prod
WORKDIR /var/www/html


COPY --chown=www-data:www-data . .
COPY --chown=www-data:www-data --from=deps /var/www/html/vendor /var/www/html/vendor
COPY --chown=www-data:www-data --from=frontend /app/public/build /var/www/html/public/build


RUN composer dump-autoload --optimize
RUN php artisan optimize


RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
RUN chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache
