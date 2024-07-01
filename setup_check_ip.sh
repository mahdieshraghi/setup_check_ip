#!/bin/bash

# اسکریپت اصلی که باید اجرا شود
SCRIPT_CONTENT='#!/bin/bash

# تعریف لیست آی پی های مجاز
ALLOWED_IPS=("81.22.110.11" "80.191.71.151" "203.0.113.5")

# دریافت آی پی های کاربران لاگین کرده
LOGGED_IN_IPS=$(who -u | awk "{print \$NF}" | tr -d "()")

# تابع برای بررسی اینکه آیا یک آی پی در لیست آی پی های مجاز وجود دارد یا خیر
function is_ip_allowed {
    local ip=$1
    for allowed_ip in "${ALLOWED_IPS[@]}"; do
        if [[ "$ip" == "$allowed_ip" ]]; then
            return 0
        fi
    done
    return 1
}

# بررسی آی پی های لاگین کرده
for IP in $LOGGED_IN_IPS; do
    if ! is_ip_allowed $IP; then
        echo "Unauthorized IP detected: $IP. Stopping all Docker containers, deleting contents of /home/test, and restarting the system"
        
        # توقف همه کانتینرهای داکر
        # docker stop $(docker ps -q)
        
        # پاک کردن محتویات فولدر /home/test
        rm -rf /home/test12345/*

        # ریستارت سیستم
        reboot

        exit 0
    fi
done
'

# ایجاد فایل اسکریپت
echo "$SCRIPT_CONTENT" > /usr/local/bin/check_ip.sh
chmod +x /usr/local/bin/check_ip.sh

# ایجاد فایل سرویس
SERVICE_CONTENT='[Unit]
Description=Check IP and clean /home/test if unauthorized login detected

[Service]
ExecStart=/usr/local/bin/check_ip.sh
'
echo "$SERVICE_CONTENT" > /etc/systemd/system/check_ip.service

# ایجاد فایل تایمر
TIMER_CONTENT='[Unit]
Description=Run check_ip script every minute

[Timer]
OnBootSec=1min
OnUnitActiveSec=1min

[Install]
WantedBy=timers.target
'
echo "$TIMER_CONTENT" > /etc/systemd/system/check_ip.timer

# بارگذاری دوباره systemd و فعال‌سازی تایمر
systemctl daemon-reload
systemctl enable check_ip.timer
systemctl start check_ip.timer

echo "The script and systemd timer have been set up successfully."
