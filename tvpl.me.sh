#!/bin/bash

# Список доменов
DOMAINS=(
    "1.tvpl.me" "3.tvpl.me" "4.tvpl.me" "6.tvpl.me" "2.tvpl.me"
    "5.tvpl.me" "7.tvpl.me" "11.tvpl.me" "12.tvpl.me" "10.tvpl.me"
    "9.tvpl.me" "8.tvpl.me" "13.tvpl.me" "16.tvpl.me" "hk.tvpl.me"
    "de.tvpl.me" "15.tvpl.me" "14.tvpl.me" "ru.tvpl.me" "ru2.tvpl.me"
    "ru3.tvpl.me" "nl.tvpl.me" "nl2.tvpl.me" "ru7.tvpl.me" "ua.tvpl.me"
    "ua2.tvpl.me" "ru4.tvpl.me" "ru5.tvpl.me" "ru6.tvpl.me" "17.tvpl.me" "pl.tvpl.me"
)

# Заголовки таблицы
echo -e "\e[1;34m%-18s %-10s %-12s %-10s %-6s %-25s %-15s\e[0m" "DOMAIN" "PING" "LATENCY" "SSL DAYS" "LOC" "AS NAME" "STATUS"
echo "----------------------------------------------------------------------------------------------------------------"

for DOMAIN in "${DOMAINS[@]}"; do
    # 0. Сначала резолвим домен в IP
    IP=$(dig +short "$DOMAIN" | tail -n1)

    if [ -z "$IP" ]; then
        LOC="??"
        AS_NAME="DNS Error"
    else
        # Теперь запрашиваем данные по конкретному IP
        LOC=$(curl -s "https://ipinfo.io/$IP/country" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        AS_NAME=$(curl -s "https://ipinfo.io/$IP/org" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | cut -c1-25)
    fi

    [ -z "$LOC" ] && LOC="??"
    [ -z "$AS_NAME" ] && AS_NAME="Unknown"

    # 1. Проверка Пинга
    PING_OUT=$(ping -c 1 -W 1 "$DOMAIN" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        PING_RES="\e[1;32mUP\e[0m"
        LATENCY=$(echo "$PING_OUT" | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1 " ms"}')
    else
        PING_RES="\e[1;31mDOWN\e[0m"
        LATENCY="---"
    fi

    # 2. Проверка SSL
    END_DATE_STR=$(timeout 3 openssl s_client -servername "$DOMAIN" -connect "$DOMAIN":443 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)

    if [ -z "$END_DATE_STR" ]; then
        SSL_DAYS="N/A"
        STATUS="\e[1;31mSSL ERROR\e[0m"
    else
        END_DATE_S=$(date -d "$END_DATE_STR" +%s)
        CURRENT_DATE_S=$(date +%s)
        DAYS_LEFT=$(( (END_DATE_S - CURRENT_DATE_S) / 86400 ))
        SSL_DAYS="$DAYS_LEFT"

        if [ "$DAYS_LEFT" -le 0 ]; then
            STATUS="\e[1;31mEXPIRED\e[0m"
        elif [ "$DAYS_LEFT" -le 4 ]; then
            STATUS="\e[1;33mRENEW SOON\e[0m"
        else
            STATUS="\e[1;32mOK\e[0m"
        fi
    fi

    # Вывод данных
    printf "%-18s %-20b %-12s %-10s %-6s %-25s %b\n" "$DOMAIN" "$PING_RES" "$LATENCY" "$SSL_DAYS" "$LOC" "$AS_NAME" "$STATUS"
done
