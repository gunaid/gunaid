#!/bin/bash

set -e

echo "🚀 Starting installation of Radash..."

# 1. تثبيت المتطلبات الأساسية
sudo apt update && sudo apt install -y git docker.io docker-compose

# 2. تحميل المشروع من GitHub
cd /opt
sudo git clone https://github.com/Ogwenya/radash.git
cd radash

# 3. إنشاء ملف البيئة .env
cat <<EOF | sudo tee .env
# Node
NODE_ENV=production

# Timezone
TIMEZONE=EAT
TIMEZONE_IANA=Africa/Nairobi

# Radius
RADIUS_SECRET=RadashSuperSecret

# JWT
JWT_SECRET=RadashJWTSecret

# Database (تم تغيير البيانات لتجنب تعارض مع RadiusDesk)
MYSQL_ROOT_PASSWORD=radash_root_pw
MYSQL_USER=radash_user
MYSQL_PASSWORD=radash_pass
MYSQL_DATABASE=radash_db

# Email
EMAIL_ADDRESS=example@gmail.com
EMAIL_PASSWORD=yourpassword
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587

# SMS (AfricasTalking)
AFRICAS_TALKING_API_KEY=your_api_key
AFRICAS_TALKING_USERNAME=your_username
AFRICAS_TALKING_SENDER_ID=your_sender_id

# MPESA
CALLBACK_URL=https://yourdomain.com/callback
MPESA_CONSUMER_KEY=your_consumer_key
MPESA_SECRET_KEY=your_secret_key
MPESA_PAYBILL=123456
MPESA_PASSKEY=your_passkey

# Frontend
DASHBOARD_API_KEY=change_this_key
DASHBOARD_URL=http://localhost:3000

# Next-auth
NEXTAUTH_SECRET=next_auth_secret
NEXTAUTH_URL=http://localhost:3000
EOF

# 4. تشغيل Radash باستخدام Docker Compose
sudo docker-compose up -d

echo "✅ Radash installation complete!"
echo "🌍 Access the Dashboard at: http://<your-server-ip>:3000"
