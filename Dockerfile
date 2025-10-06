# Use official PHP with Apache
FROM php:8.4-apache

# Install required PHP extensions for phpBB
RUN apt-get update && apt-get install -y \
libpng-dev \
libjpeg-dev \
libfreetype6-dev \
libzip-dev \
libxml2-dev \
libpq-dev \
unzip \
&& docker-php-ext-configure gd --with-freetype --with-jpeg \
&& docker-php-ext-install gd pdo pdo_pgsql pgsql mbstring xml simplexml dom zip opcache zlib ftp

# Enable Apache mods
RUN a2enmod rewrite headers

# Download phpBB
WORKDIR /var/www/html
RUN curl -L https://download.phpbb.com/pub/release/3.3/3.3.15/phpBB-3.3.15.zip -o phpbb.zip \
    && unzip phpbb.zip \
    && mv phpBB3/* ./ \
    && rm -rf phpbb.zip phpBB3

# Fix permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

EXPOSE 80
