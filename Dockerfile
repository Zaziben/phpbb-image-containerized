
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

# Install for debug purposes
RUN apt-get install postgresql postgresql-contrib -y
RUN apt-get install vim -y

# Download phpBB
WORKDIR /var/www/html
RUN curl -L https://download.phpbb.com/pub/release/3.3/3.3.15/phpBB-3.3.15.zip -o phpbb.zip \
    && unzip phpbb.zip \
    && mv phpBB3/* ./ \
    && rm -rf phpbb.zip phpBB3

RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 777 /var/www/html

# Install dependancies for mountpoint
RUN apt-get update && apt-get install -y \
    ca-certificates \
    fuse \
    && rm -rf /var/lib/apt/lists/*

# Install mount-s3
RUN curl -Lo /usr/local/bin/mount-s3 \
    https://s3.amazonaws.com/mountpoint-s3-release/latest/x86_64/mount-s3 \
    && chmod +x /usr/local/bin/mount-s3

# Create mount point
RUN mkdir -p /mnt/phpbb-s3

# Entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]



EXPOSE 80
