#!/bin/bash

echo "➕ إضافة مستخدم جديد في قاعدة بيانات RadiusDesk"

read -p "📝 اسم المستخدم: " username
read -s -p "🔑 كلمة المرور: " password
echo ""
read -p "📛 المجموعة (group_id) [default: 1]: " group_id
group_id=${group_id:-1}

if [ -z "$username" ] || [ -z "$password" ]; then
    echo "❌ يجب إدخال اسم المستخدم وكلمة المرور."
    exit 1
fi

echo "🔄 إضافة المستخدم '$username' إلى قاعدة البيانات..."

mysql -u root -p -e "USE rd; INSERT INTO users (username, password, group_id, active) VALUES ('${username}', SHA1('${password}'), ${group_id}, 1);"

if [ $? -eq 0 ]; then
    echo "✅ تم إضافة المستخدم بنجاح!"
else
    echo "❌ فشل في إضافة المستخدم. تأكد من أن اسم المستخدم غير مكرر."
fi
