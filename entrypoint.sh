#!/usr/bin/bash
set -e

echo "Starting container entrypoint..."
echo "Mounting S3 bucket with Mountpoint..."

mount-s3 dnd-forum-s3-jv /mnt/phpbb-s3

echo "Linking phpBB directories..."

rm -rf /var/www/html/files
rm -rf /var/www/html/store
rm -rf /var/www/html/images/avatars/upload

ln -s /mnt/phpbb-s3/files   /var/www/html/files
ln -s /mnt/phpbb-s3/store   /var/www/html/store
ln -s /mnt/phpbb-s3/avatars /var/www/html/images/avatars/upload

echo "Starting Apache..."
exec "$@"

