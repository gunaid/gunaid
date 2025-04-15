#!/bin/bash

echo "### تحديث النظام وتثبيت الحزم الأساسية"
apt update && apt upgrade -y
apt install software-properties-common curl unzip git -y

echo "### تثبيت قاعدة بيانات MariaDB"
apt install mariadb-server mariadb-client -y
systemctl enable mariadb
systemctl start mariadb

echo "### إعداد قاعدة البيانات"
mysql -u root <<EOF
CREATE DATABASE radius;
CREATE USER 'radius'@'localhost' IDENTIFIED BY 'radiuspass';
GRANT ALL PRIVILEGES ON radius.* TO 'radius'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "### تثبيت PHP 8.1 والإضافات"
add-apt-repository ppa:ondrej/php -y
apt update
apt install php8.1 php8.1-cli php8.1-fpm php8.1-mysql php8.1-gd php8.1-curl php8.1-mbstring php8.1-xml php8.1-zip -y
systemctl enable php8.1-fpm
systemctl start php8.1-fpm

echo "### تثبيت Nginx"
apt install nginx -y
systemctl enable nginx
systemctl start nginx

echo "### تثبيت FreeRADIUS"
apt install freeradius freeradius-mysql freeradius-utils -y
systemctl enable freeradius
systemctl start freeradius

echo "### تنزيل قاعدة بيانات RadiusDesk"
cd /tmp
wget https://radiusdesk.com/downloads/radiusdesk-sql.zip
unzip radiusdesk-sql.zip
mysql -u radius -pradiuspass radius < radius-mysql.sql
mysql -u radius -pradiuspass radius < radiusdesk.sql

echo "### إعداد مجلد الواجهة (يدوياً لاحقاً)"
mkdir -p /var/www/html/rd
echo "<h2>RadiusDesk Installed. Add Frontend manually.</h2>" > /var/www/html/rd/index.html

echo "### إعداد Nginx بسيط مؤقت"
cat <<EOL > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    root /var/www/html;
    index index.php index.html index.htm;
    server_name _;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOL

nginx -t && systemctl restart nginx

echo "### تم التثبيت بنجاح. افتح الآن: http://[your_server_ip]/rd"
