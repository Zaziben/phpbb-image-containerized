#!/usr/bin/bash
set -e

echo "Starting container entrypoint..."

# /mnt/phpbb-s3 is mounted by ECS from EFS - no mount command needed
echo "Linking phpBB directories to EFS mount..."

rm -rf /var/www/html/files
rm -rf /var/www/html/store
rm -rf /var/www/html/images/avatars/upload

ln -s /mnt/phpbb-s3/files   /var/www/html/files
ln -s /mnt/phpbb-s3/store   /var/www/html/store
ln -s /mnt/phpbb-s3/avatars /var/www/html/images/avatars/upload

echo "Creating EFS subdirectories if first run..."
mkdir -p /mnt/phpbb-s3/files \
         /mnt/phpbb-s3/store \
         /mnt/phpbb-s3/avatars

echo "Writing config.php from secret..."
printf '%s' "$PHPBB_CONFIG" > /var/www/html/config.php
chown www-data:www-data /var/www/html/config.php
chmod 640 /var/www/html/config.php


echo "Starting Apache..."
exec "$@"
