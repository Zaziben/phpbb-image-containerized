
<?php
$dbms = 'pgsql';
$dbhost = getenv('DB_HOST');
$dbport = '5432'
$dbname = getenv('DB_NAME');
$dbuser = getenv('DB_USER');
$dbpasswd = getenv('DB_PASSWORD');
$table_prefix = 'phpbb_';
$acm_type = 'phpbb\\cache\\driver\\file';
$load_extensions = '';
?>
