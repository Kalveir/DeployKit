#!/bin/bash

# --- Automatic PHP version detection ---
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

# --- Kalkulasi Spesifikasi Hardware ---
# Menghitung RAM total dalam MB
TOTAL_RAM=$(grep MemTotal /proc/meminfo | awk '{print int($2/1024)}')

# Estimasi rata-rata penggunaan memori per proses PHP-FPM dalam MB.
# Nilai ini bisa bervariasi tergantung aplikasi (misalnya, WordPress, Laravel).
# 30MB adalah nilai konservatif, Anda bisa menyesuaikannya.
PHP_PROCESS_MEMORY=30

# Menghitung max_children berdasarkan 70% dari total RAM, dibagi dengan memori per proses.
# Kami menyisakan 30% RAM untuk sistem operasi dan layanan lain (Nginx, database, dll.).
MAX_CHILDREN=$(awk "BEGIN {print int(($TOTAL_RAM * 0.7) / $PHP_PROCESS_MEMORY)}")

# Menghitung nilai lain berdasarkan MAX_CHILDREN
# Nilai-nilai ini adalah rekomendasi umum.
START_SERVERS=$(awk "BEGIN {print int($MAX_CHILDREN / 5)}")
MIN_SPARE=$(awk "BEGIN {print int($MAX_CHILDREN / 10)}")
MAX_SPARE=$(awk "BEGIN {print int($MAX_CHILDREN / 4)}")

# Pastikan nilai tidak kurang dari 1 atau 2
if [ "$MAX_CHILDREN" -eq 0 ]; then
  MAX_CHILDREN=5
fi
if [ "$START_SERVERS" -eq 0 ]; then
  START_SERVERS=2
fi
if [ "$MIN_SPARE" -eq 0 ]; then
  MIN_SPARE=1
fi
if [ "$MAX_SPARE" -eq 0 ]; then
  MAX_SPARE=2
fi

echo "✅ Menghitung konfigurasi PHP-FPM berdasarkan RAM: ${TOTAL_RAM}MB"
echo "   - pm.max_children: $MAX_CHILDREN"
echo "   - pm.start_servers: $START_SERVERS"
echo "   - pm.min_spare_servers: $MIN_SPARE"
echo "   - pm.max_spare_servers: $MAX_SPARE"

# --- Update php.ini ---
echo "✅ Updating php.ini..."
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
sed -i "s/^pm.max_children = .*/pm.max_children = $MAX_CHILDREN/" "$FPM_POOL_CONF"
sed -i "s/^pm.start_servers = .*/pm.start_servers = $START_SERVERS/" "$FPM_POOL_CONF"
sed -i "s/^pm.min_spare_servers = .*/pm.min_spare_servers = $MIN_SPARE/" "$FPM_POOL_CONF"
sed -i "s/^pm.max_spare_servers = .*/pm.max_spare_servers = $MAX_SPARE/" "$FPM_POOL_CONF"
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