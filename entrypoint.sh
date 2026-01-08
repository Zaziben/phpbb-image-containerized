#!/bin/sh
set -e

echo "Mounting S3 bucket..."

mount-s3 \
  --allow-other \
  dnd-forum-s3-jv \
  /mnt/phpbb-s3

echo "Linking phpBB directories..."

ln -sf /mnt/phpbb-s3/files   /var/www/html/phpbb/files
ln -sf /mnt/phpbb-s3/store   /var/www/html/phpbb/store
ln -sf /mnt/phpbb-s3/avatars /var/www/html/phpbb/images/avatars/upload

exec "$@"

