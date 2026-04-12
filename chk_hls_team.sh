#!/bin/bash

# Список доменов для проверки
DOMAINS=(
    "1.hls.ga" "3.hls.ga" "4.hls.ga" "6.hls.ga" "2.hls.ga"
    "5.hls.ga" "7.hls.ga" "11.hls.ga" "12.hls.ga" "10.hls.ga"
    "9.hls.ga" "8.hls.ga" "13.hls.ga" "16.hls.ga" "hk.hls.ga"
    "de.hls.ga" "15.hls.ga" "14.hls.ga" "ru.hls.ga" "ru2.hls.ga"
    "ru3.hls.ga" "nl.hls.ga" "nl2.hls.ga" "ru7.hls.ga" "ua.hls.ga"
    "ua2.hls.ga" "ru4.hls.ga" "ru5.hls.ga" "ru6.hls.ga" "17.hls.ga" "pl.hls.ga"
)

# Заголовки таблицы
echo -e "\e[1;34m%-18s %-10s %-10s %-15s\e[0m" "DOMAIN" "PING" "SSL DAYS" "STATUS"
echo "-----------------------------------------------------------------------"

for DOMAIN in "${DOMAINS[@]}"; do
    # 1. Проверка Пинга (отправляем 1 пакет, ожидание 1 сек)
    if ping -c 1 -W 1 "$DOMAIN" > /dev/null 2>&1; then
        PING_RES="\e[1;32mUP\e[0m"
    else
        PING_RES="\e[1;31mDOWN\e[0m"
    fi

    # 2. Проверка SSL сертификата (порт 443)
    END_DATE_STR=$(timeout 2 openssl s_client -servername "$DOMAIN" -connect "$DOMAIN":443 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)

    if [ -z "$END_DATE_STR" ]; then
        SSL_DAYS="N/A"
        STATUS="\e[1;31mSSL ERROR\e[0m"
    else
        # Вычисление дней до истечения
        END_DATE_S=$(date -d "$END_DATE_STR" +%s)
        CURRENT_DATE_S=$(date +%s)
        DAYS_LEFT=$(( (END_DATE_S - CURRENT_DATE_S) / 86400 ))
        SSL_DAYS="$DAYS_LEFT"

        if [ "$DAYS_LEFT" -le 0 ]; then
            STATUS="\e[1;31mEXPIRED\e[0m"
        elif [ "$DAYS_LEFT" -le 14 ]; then
            STATUS="\e[1;33mRENEW SOON\e[0m"
        else
            STATUS="\e[1;32mOK\e[0m"
        fi
    fi

    # Вывод строки данных
    printf "%-18s %-20b %-10s %b\n" "$DOMAIN" "$PING_RES" "$SSL_DAYS" "$STATUS"
done
