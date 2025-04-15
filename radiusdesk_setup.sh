
#!/bin/bash

# Exit on any error
set -e

echo "🔧 Updating and installing dependencies..."
sudo apt update && sudo apt -y upgrade
sudo apt install -y language-pack-en-base software-properties-common

echo "🌐 Installing and configuring NGINX..."
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx

echo "⚙️ Installing PHP and required extensions..."
sudo apt install -y php-fpm php-cli php-mysql php-gd php-curl php-xml php-mbstring php-intl php-sqlite3
sudo systemctl enable php8.3-fpm
sudo systemctl start php8.3-fpm

echo "🛠️ Configuring NGINX to support PHP..."
NGINX_DEFAULT="/etc/nginx/sites-enabled/default"
sudo sed -i 's/index index.html/index index.php index.html/' $NGINX_DEFAULT
sudo tee -a $NGINX_DEFAULT > /dev/null <<EOL

location ~ \.php\$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
}

location ~ /\.ht {
    deny all;
}

location /cake4/rd_cake/node-reports/submit_report.json {
    try_files \$uri \$uri/ /reporting/reporting.php;
}

location /cake4/rd_cake {
    rewrite ^/cake4/rd_cake(.+)\$ /cake4/rd_cake/webroot\$1 break;
    try_files \$uri \$uri/ /cake4/rd_cake/index.php\$is_args\$args;
}

location ~ ^/cake4/.+\.(jpg|jpeg|gif|png|ico|js|css)\$ {
    rewrite ^/cake4/rd_cake/webroot/(.*)\$ /cake4/rd_cake/webroot/\$1 break;
    rewrite ^/cake4/rd_cake/(.*)\$ /cake4/rd_cake/webroot/\$1 break;
    access_log off;
    expires max;
    add_header Cache-Control public;
}
EOL

sudo systemctl reload nginx

echo "📦 Installing MariaDB..."
sudo apt install -y mariadb-server
sudo systemctl enable mariadb
sudo systemctl restart mariadb

echo "🔧 Disabling MariaDB strict mode..."
sudo tee /etc/mysql/conf.d/disable_strict_mode.cnf > /dev/null <<EOF
[mysqld]
sql_mode=IGNORE_SPACE,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION
EOF

echo "🔄 Enabling MariaDB event scheduler..."
sudo tee /etc/mysql/conf.d/enable_event_scheduler.cnf > /dev/null <<EOF
[mysqld]
event_scheduler=on
EOF

sudo systemctl restart mariadb

echo "📁 Cloning RADIUSdesk source code..."
cd /var/www
sudo git clone https://github.com/RADIUSdesk/rdcore.git
sudo git clone https://github.com/RADIUSdesk/rd_mobile.git

echo "🔗 Creating symbolic links..."
cd /var/www/html
sudo ln -s ../rdcore/rd ./rd
sudo ln -s ../rdcore/cake4 ./cake4
sudo ln -s ../rdcore/login ./login
sudo ln -s ../rdcore/AmpConf/build/production/AmpConf ./conf_dev
sudo ln -s ../rdcore/cake4/rd_cake/setup/scripts/reporting ./reporting
sudo ln -s ../rd_mobile/build/production/RdMobile ./rd_mobile

echo "🔐 Fixing permissions..."
sudo mkdir -p /var/www/html/cake4/rd_cake/logs
sudo mkdir -p /var/www/html/cake4/rd_cake/webroot/files/imagecache
sudo mkdir -p /var/www/html/cake4/rd_cake/tmp
for dir in logs tmp webroot/files/imagecache webroot/img/realms webroot/img/dynamic_details webroot/img/dynamic_photos webroot/img/access_providers webroot/img/hardwares; do
  sudo mkdir -p /var/www/html/cake4/rd_cake/$dir
  sudo chown -R www-data:www-data /var/www/html/cake4/rd_cake/$dir
done

echo "🗃️ Setting up timezone in MySQL..."
sudo mysql_tzinfo_to_sql /usr/share/zoneinfo | sudo mysql -u root mysql

echo "🧱 Creating and populating database..."
sudo mysql -u root <<EOF
CREATE DATABASE rd;
GRANT ALL PRIVILEGES ON rd.* TO 'rd'@'127.0.0.1' IDENTIFIED BY 'rd';
GRANT ALL PRIVILEGES ON rd.* TO 'rd'@'localhost' IDENTIFIED BY 'rd';
EOF

sudo mysql -u root rd < /var/www/html/cake4/rd_cake/setup/db/rd.sql
sudo mysql -u root rd < /var/www/rdcore/cake4/rd_cake/setup/db/8.068_add_email_sms_histories.sql

echo "🧹 Clearing CakePHP model cache..."
sudo rm -f /var/www/rdcore/cake4/rd_cake/tmp/cache/models/*

echo "🕘 Installing CRON jobs..."
sudo cp /var/www/html/cake4/rd_cake/setup/cron/cron4 /etc/cron.d/

echo "✅ Installation completed!"
echo "📱 Web UI: http://<your-ip>/rd_mobile"
echo "🌐 Admin UI: http://<your-ip>/rd/build/production/Rd/"
echo "🔐 Login: root / admin"
