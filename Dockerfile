FROM php:8.4-apache

# Install required dependencies for phpBB
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

# Install for debug purposes and wget
RUN apt-get install postgresql postgresql-contrib vim wget -y

WORKDIR /var/www/html

# Download phpBB
RUN curl -L https://download.phpbb.com/pub/release/3.3/3.3.15/phpBB-3.3.15.zip -o phpbb.zip \
    && unzip phpbb.zip \
    && mv phpBB3/* ./ \
    && rm -rf phpbb.zip phpBB3

# Get mountpoint s3
RUN wget https://s3.amazonaws.com/mountpoint-s3-release/latest/x86_64/mount-s3 -y

RUN sudo yum install ./mount-s3.rpm -y

RUN wget https://s3.amazonaws.com/mountpoint-s3-release/public_keys/KEYS && \
    gpg --import KEYS \
    gpg --fingerprint mountpoint-s3@amazon.com -y

RUN wget https://s3.amazonaws.com/mountpoint-s3-release/latest/x86_64/mount-s3.rpm.asc && \
    gpg --verify https://s3.amazonaws.com/mountpoint-s3-release/latest/x86_64/mount-s3.rpm.asc

RUN mount-s3 dnd-forum-s3-jv /phpbb/files \
    mount-s3 dnd-forum-s3-jv /phpbb/store \
    mount-s3 dnd-forum-s3-jv /phpbb/images \


RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 777 /var/www/html

EXPOSE 80
