
FROM php:8.4-apache

# Install required dependancies for phpBB

RUN apt-get update && apt-get install -y \
    libpng-dev \
    libonig-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libxml2-dev \
    libpq-dev \
    unzip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd pdo pdo_pgsql pgsql mbstring xml zip ftp \
    && docker-php-ext-enable opcache
# Enable Apache mods

RUN a2enmod rewrite headers
# test run 
# Install for debug purposes
RUN apt-get install postgresql postgresql-contrib -y
RUN apt-get install vim -y

# Download phpBB
WORKDIR /var/www/html
RUN curl -L https://download.phpbb.com/pub/release/3.3/3.3.15/phpBB-3.3.15.zip -o phpbb.zip \
    && unzip phpbb.zip \
    && mv phpBB3/* ./ \
    && rm -rf phpbb.zip phpBB3

# For s3 extension
RUN apt-get update && \
    apt-get install -y git unzip && \
    apt-get clean

WORKDIR /var/www/html/phpbb

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
 && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
 && php -r "unlink('composer-setup.php');"

WORKDIR /var/www/html/phpbb/ext

RUN mkdir austinmaddox \
 && git clone --branch patch-1 https://github.com/Zaziben/phpbb-extension-s3.git austinmaddox/s3 \
 && cd austinmaddox/s3 \
 && composer install --no-interaction --ignore-platform-reqs

RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 777 /var/www/html

EXPOSE 80
