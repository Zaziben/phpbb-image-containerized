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
    fuse3 \
    ca-certificates \
    unzip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd pdo pdo_pgsql pgsql mbstring xml zip ftp \
    && docker-php-ext-enable opcache

# Enable Apache mods
RUN a2enmod rewrite headers

# Install Mountpoint for S3 (official AWS build)
RUN curl -Lo /tmp/mountpoint.deb \
    https://s3.amazonaws.com/mountpoint-s3-release/latest/x86_64/mount-s3.deb \
    && apt-get install -y /tmp/mountpoint.deb \
    && rm /tmp/mountpoint.deb

# Install for debug purposes
RUN apt-get install postgresql postgresql-contrib vim -y

WORKDIR /var/www/html

# Download phpBB
RUN curl -L https://download.phpbb.com/pub/release/3.3/3.3.15/phpBB-3.3.15.zip -o phpbb.zip \
    && unzip phpbb.zip \
    && mv phpBB3/* ./ \
    && rm -rf phpbb.zip phpBB3

# Copy entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["apache2-foreground"]

RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 777 /var/www/html

EXPOSE 80
