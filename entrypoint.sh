#!/bin/sh
set -euo pipefail

echo "Starting container entrypoint..."
echo "Mounting S3 bucket using Mountpoint..."

# Explicit absolute path to avoid shadowing issues
/usr/bin/mount-s3 \
  --allow-other \
  dnd-forum-s3-jv \
  /mnt/phpbb-s3

echo "S3 mount successful. Linking phpBB directories..."

# Ensure target directories exist
mkdir -p /var/www/html/phpbb/files
mkdir -p /var/www/html/phpbb/store
mkdir -p /var/www/html/phpbb/images/avatars/upload

# Symlink phpBB writable directories to S3
ln -sfn /mnt/phpbb-s3/files   /var/www/html/phpbb/files
ln -sfn /mnt/phpbb-s3/store   /var/www/html/phpbb/store
ln -sfn /mnt/phpbb-s3/avatars /var/www/html/phpbb/images/avatars/upload

echo "Starting main container process..."
exec "$@"

