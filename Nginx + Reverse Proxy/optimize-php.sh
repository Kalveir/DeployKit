#!/bin/bash

# --- Automatic PHP version detection ---
# Find the highest PHP version installed.
PHP_VERSION=$(ls /etc/php | sort -V | tail -n 1)

if [ -z "$PHP_VERSION" ]; then
    echo "❌ Error: No PHP version found in /etc/php/"
    exit 1
fi

PHP_INI="/etc/php/$PHP_VERSION/fpm/php.ini"
FPM_POOL_CONF="/etc/php/$PHP_VERSION/fpm/pool.d/www.conf"
FPM_SERVICE="php$PHP_VERSION-fpm"

# --- Additions Start ---
echo "⚙️ Creating log directory for PHP-FPM..."
sudo mkdir -p /var/log/php-fpm
sudo chown www-data:www-data /var/log/php-fpm
sudo chmod 755 /var/log/php-fpm
# --- Additions End ---

echo "🛠 Optimizing PHP-FPM and Zend OPcache for PHP $PHP_VERSION..."

# Check if config files exist before proceeding.
if [ ! -f "$PHP_INI" ] || [ ! -f "$FPM_POOL_CONF" ]; then
    echo "❌ Error: Configuration files not found for PHP $PHP_VERSION."
    echo "PHP_INI: $PHP_INI"
    echo "FPM_POOL_CONF: $FPM_POOL_CONF"
    exit 1
fi

# Backup original configs to prevent data loss.
cp "$PHP_INI" "${PHP_INI}.bak"
cp "$FPM_POOL_CONF" "${FPM_POOL_CONF}.bak"

# --- Update php.ini ---
echo "✅ Updating php.ini..."

# The 'zend_extension' line is deliberately NOT touched here,
# as it's typically managed by separate .ini files in conf.d
# and adding it manually can cause conflicts.
sed -i "s/^;*opcache.enable=.*/opcache.enable=1/" "$PHP_INI"
sed -i "s/^;*opcache.enable_cli=.*/opcache.enable_cli=1/" "$PHP_INI"
sed -i "s/^;*opcache.memory_consumption=.*/opcache.memory_consumption=256/" "$PHP_INI"
sed -i "s/^;*opcache.interned_strings_buffer=.*/opcache.interned_strings_buffer=16/" "$PHP_INI"
sed -i "s/^;*opcache.max_accelerated_files=.*/opcache.max_accelerated_files=20000/" "$PHP_INI"
sed -i "s/^;*opcache.revalidate_freq=.*/opcache.revalidate_freq=0/" "$PHP_INI"
sed -i "s/^;*opcache.validate_timestamps=.*/opcache.validate_timestamps=0/" "$PHP_INI"
sed -i "s/^;*realpath_cache_size =.*/realpath_cache_size = 4096k/" "$PHP_INI"
sed -i "s/^;*realpath_cache_ttl =.*/realpath_cache_ttl = 600/" "$PHP_INI"
sed -i "s/^;*memory_limit =.*/memory_limit = 256M/" "$PHP_INI"

# --- Update FPM Pool Config ---
echo "✅ Updating www.conf..."

sed -i "s/^pm = .*/pm = dynamic/" "$FPM_POOL_CONF"
sed -i "s/^pm.max_children = .*/pm.max_children = 50/" "$FPM_POOL_CONF"
sed -i "s/^pm.start_servers = .*/pm.start_servers = 10/" "$FPM_POOL_CONF"
sed -i "s/^pm.min_spare_servers = .*/pm.min_spare_servers = 5/" "$FPM_POOL_CONF"
sed -i "s/^pm.max_spare_servers = .*/pm.max_spare_servers = 20/" "$FPM_POOL_CONF"
sed -i "s/^;*pm.max_requests = .*/pm.max_requests = 500/" "$FPM_POOL_CONF"

# Enable slowlog.
echo "✅ Enabling slowlog..."
sed -i "s|^;*request_slowlog_timeout = .*|request_slowlog_timeout = 5s|" "$FPM_POOL_CONF"
sed -i "s|^;*slowlog = .*|slowlog = /var/log/php-fpm/slowlog-$PHP_VERSION.log|" "$FPM_POOL_CONF"

# Set proper socket for Nginx.
echo "✅ Ensuring socket config is correct..."
sed -i "s|^listen = .*|listen = /run/php/php$PHP_VERSION-fpm.sock|" "$FPM_POOL_CONF"
sed -i "s|^;listen.mode = .*|listen.mode = 0660|" "$FPM_POOL_CONF"

# Restart PHP-FPM service to apply changes.
echo "♻️ Restarting PHP-FPM..."
service "$FPM_SERVICE" restart

echo "✅ Done! PHP-FPM and OPcache optimized for PHP $PHP_VERSION."