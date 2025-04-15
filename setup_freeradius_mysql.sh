#!/bin/bash

echo "### تثبيت FreeRADIUS وموديول MySQL"
apt update
apt install freeradius freeradius-mysql -y

echo "### تفعيل الاتصال بقاعدة البيانات"
# تعديل ملف sql
SQL_MOD="/etc/freeradius/3.0/mods-available/sql"

if [ -f "$SQL_MOD" ]; then
    sed -i 's/^#.*dialect =.*/dialect = "mysql"/' $SQL_MOD
    sed -i 's/^#.*server =.*/server = "localhost"/' $SQL_MOD
    sed -i 's/^#.*login =.*/login = "rd"/' $SQL_MOD
    sed -i 's/^#.*password =.*/password = "rd"/' $SQL_MOD
    sed -i 's/^#.*radius_db =.*/radius_db = "rd"/' $SQL_MOD

    ln -sf $SQL_MOD /etc/freeradius/3.0/mods-enabled/sql
else
    echo "ملف إعداد SQL غير موجود: $SQL_MOD"
    exit 1
fi

echo "### تفعيل sql في default & inner-tunnel"

DEFAULT_SITE="/etc/freeradius/3.0/sites-available/default"
INNER_TUNNEL="/etc/freeradius/3.0/sites-available/inner-tunnel"

for FILE in $DEFAULT_SITE $INNER_TUNNEL; do
    sed -i '/authorize {/,/}/s/^#*\s*sql/sql/' $FILE
    sed -i '/accounting {/,/}/s/^#*\s*sql/sql/' $FILE
    sed -i '/session {/,/}/s/^#*\s*sql/sql/' $FILE
    sed -i '/post-auth {/,/}/s/^#*\s*sql/sql/' $FILE
done

echo "### إعادة تشغيل FreeRADIUS"
systemctl restart freeradius

echo "### تم إعداد FreeRADIUS وربطه بقاعدة بيانات rd بنجاح!"
