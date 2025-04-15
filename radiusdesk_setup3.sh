
#!/bin/bash

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_success() {
    echo -e "${GREEN}$1${NC}"
}

print_error() {
    echo -e "${RED}$1${NC}"
}

print_success "🔧 Starting full RadiusDesk setup for Ubuntu 24.04..."

# Add a sudo user if needed (optional, not enforced here)

# Update and install required packages
print_success "🧩 Updating system and installing required packages..."
sudo apt update && sudo apt -y upgrade
sudo apt -y install language-pack-en-base nginx php php-fpm mariadb-server php-mysql php-gd php-curl php-xml php-mbstring php-intl php-sqlite3 php-cli git wget unzip freeradius freeradius-mysql

# Enable and start services
sudo systemctl enable --now nginx
sudo systemctl enable --now php8.3-fpm
sudo systemctl enable --now mariadb
sudo systemctl enable --now freeradius

# Configure PHP-FPM in NGINX
echo "🛠️ Configuring NGINX..."
NGINX_CONF="/etc/nginx/sites-available/default"
sudo sed -i 's/index index.html/index index.php index.html/' "$NGINX_CONF"
sudo sed -i '/location ~ \.php\$/d' "$NGINX_CONF"
sudo sed -i '/server_name _;/a     location ~ \.php$ {\n        include snippets/fastcgi-php.conf;\n        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;\n    }\n\n    location ~ /\.ht {\n        deny all;\n    }' "$NGINX_CONF"

# Add RadiusDesk NGINX rules
sudo sed -i '$i     location /cake4/rd_cake {\n        rewrite ^/cake4/rd_cake(.+)$ /cake4/rd_cake/webroot$1 break;\n        try_files $uri $uri/ /cake4/rd_cake/index.php$is_args$args;\n    }\n\n    location /cake4/rd_cake/node-reports/submit_report.json {\n        try_files $uri $uri/ /reporting/reporting.php;\n    }' "$NGINX_CONF"

sudo nginx -t && sudo systemctl reload nginx

# Clone RadiusDesk repos
print_success "📥 Cloning RadiusDesk repositories..."
cd /var/www
sudo git clone https://github.com/RADIUSdesk/rdcore.git
sudo git clone https://github.com/RADIUSdesk/rd_mobile.git

# Create symbolic links
cd /var/www/html
sudo ln -s ../rdcore/rd ./rd
sudo ln -s ../rdcore/cake4 ./cake4
sudo ln -s ../rdcore/login ./login
sudo ln -s ../rdcore/AmpConf/build/production/AmpConf ./conf_dev
sudo ln -s ../rdcore/cake4/rd_cake/setup/scripts/reporting ./reporting
sudo ln -s ../rd_mobile/build/production/RdMobile ./rd_mobile

# Permissions setup
sudo mkdir -p /var/www/html/cake4/rd_cake/{logs,webroot/files/imagecache,tmp}
sudo chown -R www-data:www-data /var/www/html/cake4/rd_cake/tmp
sudo chown -R www-data:www-data /var/www/html/cake4/rd_cake/logs
sudo chown -R www-data:www-data /var/www/html/cake4/rd_cake/webroot/img/{realms,dynamic_details,dynamic_photos,access_providers,hardwares}
sudo chown -R www-data:www-data /var/www/html/cake4/rd_cake/webroot/files/imagecache

# Configure MariaDB timezone
print_success "🌐 Importing timezone info into MySQL..."
sudo mysql_tzinfo_to_sql /usr/share/zoneinfo | sudo mysql -u root mysql

# Disable strict mode
cat <<EOF | sudo tee /etc/mysql/conf.d/disable_strict_mode.cnf
[mysqld]
sql_mode=IGNORE_SPACE,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION
EOF

# Enable event scheduler
cat <<EOF | sudo tee /etc/mysql/conf.d/enable_event_scheduler.cnf
[mysqld]
event_scheduler=on
EOF

sudo systemctl restart mariadb

# Create and populate RadiusDesk DB
print_success "🗃️ Setting up RadiusDesk database..."
sudo mysql -u root -e "CREATE DATABASE rd;"
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON rd.* TO 'rd'@'127.0.0.1' IDENTIFIED BY 'rd';"
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON rd.* TO 'rd'@'localhost' IDENTIFIED BY 'rd';"
sudo mysql -u root rd < /var/www/html/cake4/rd_cake/setup/db/rd.sql

# Apply latest patch
sudo mysql -u root rd < /var/www/rdcore/cake4/rd_cake/setup/db/8.068_add_email_sms_histories.sql || true

# Clear CakePHP model cache
sudo rm -f /var/www/rdcore/cake4/rd_cake/tmp/cache/models/*

# Install cron jobs
sudo cp /var/www/html/cake4/rd_cake/setup/cron/cron4 /etc/cron.d/

# Configure FreeRADIUS with SQL
print_success "📦 Configuring FreeRADIUS SQL module..."
sudo ln -sf /etc/freeradius/3.0/mods-available/sql /etc/freeradius/3.0/mods-enabled/
sudo sed -i 's/driver = ".*"/driver = "rlm_sql_mysql"/' /etc/freeradius/3.0/mods-available/sql
sudo sed -i 's/server = ".*"/server = "localhost"/' /etc/freeradius/3.0/mods-available/sql
sudo sed -i 's/login = ".*"/login = "rd"/' /etc/freeradius/3.0/mods-available/sql
sudo sed -i 's/password = ".*"/password = "rd"/' /etc/freeradius/3.0/mods-available/sql
sudo sed -i 's/radius_db = ".*"/radius_db = "rd"/' /etc/freeradius/3.0/mods-available/sql

sudo sed -i '/authorize {/a\        sql' /etc/freeradius/3.0/sites-available/default
sudo sed -i '/authorize {/a\        sql' /etc/freeradius/3.0/sites-available/inner-tunnel

sudo systemctl restart freeradius

print_success "✅ RadiusDesk setup complete!"
echo -e "\n🌍 Access the web UI at: http://<your-server-ip>/rd/build/production/Rd"
echo -e "📱 Access the mobile UI at: http://<your-server-ip>/rd_mobile"
echo -e "🔐 Login: Username: root | Password: admin"
