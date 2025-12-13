# Use official PHP with Apache
FROM php:8.4-apache

# Install required PHP extensions for phpBB

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

# install postgres
RUN apt install postgresql postgresql-contrib -y

# Download phpBB
WORKDIR /var/www/html
RUN curl -L https://download.phpbb.com/pub/release/3.3/3.3.15/phpBB-3.3.15.zip -o phpbb.zip \
    && unzip phpbb.zip \
    && mv phpBB3/* ./ \
    && rm -rf phpbb.zip phpBB3

# Install dependencies needed for composer + git
RUN apt-get update && \
    apt-get install -y git unzip && \
    apt-get clean

# Set working directory to phpBB root
WORKDIR /var/www/html/phpbb

# Install Composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
 && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
 && php -r "unlink('composer-setup.php');"

# Clone the extension
RUN mkdir -p ext/AustinMaddox \
 && git clone https://github.com/AustinMaddox/phpbb-extension-s3.git ext/AustinMaddox/s3 \
 && cd ext/AustinMaddox/s3 \
 && composer install --no-dev --no-interaction --prefer-dist
# Fix permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 777 /var/www/html

EXPOSE 80
