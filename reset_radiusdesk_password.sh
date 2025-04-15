#!/bin/bash

echo "🔐 إعادة تعيين كلمة مرور مستخدم RadiusDesk"

read -p "📝 أدخل اسم المستخدم [default: root]: " username
username=${username:-root}

read -s -p "🔑 أدخل كلمة المرور الجديدة [default: radius]: " password
echo ""
password=${password:-radius}

echo "🛠️ تحديث كلمة المرور للمستخدم '$username'..."

mysql -u root -p -e "USE rd; UPDATE users SET password = SHA1('${password}') WHERE username = '${username}';"

if [ $? -eq 0 ]; then
    echo "✅ تم تحديث كلمة المرور بنجاح!"
else
    echo "❌ حدث خطأ أثناء تحديث كلمة المرور."
fi
