#!/bin/bash

# Список доменов
DOMAINS=(
    "1.hls.ga" "3.hls.ga" "4.hls.ga" "6.hls.ga" "2.hls.ga"
    "5.hls.ga" "7.hls.ga" "11.hls.ga" "12.hls.ga" "10.hls.ga"
    "9.hls.ga" "8.hls.ga" "13.hls.ga" "16.hls.ga" "hk.hls.ga"
    "de.hls.ga" "15.hls.ga" "14.hls.ga" "ru.hls.ga" "ru2.hls.ga"
    "ru3.hls.ga" "nl.hls.ga" "nl2.hls.ga" "ru7.hls.ga" "ua.hls.ga"
    "ua2.hls.ga" "ru4.hls.ga" "ru5.hls.ga" "ru6.hls.ga" "17.hls.ga" "pl.hls.ga"
)

# Заголовки таблицы
echo -e "\e[1;34m%-18s %-10s %-12s %-10s %-25s %-15s\e[0m" "DOMAIN" "PING" "LATENCY" "SSL DAYS" "AS NAME" "STATUS"
echo "----------------------------------------------------------------------------------------------------"

for DOMAIN in "${DOMAINS[@]}"; do
    # 0. Получение AS Name через API (быстро и точно)
    # Запрос возвращает строку вида "AS12345 Name of Provider"
    AS_DATA=$(curl -s "http://ip-api.com/line/$DOMAIN?fields=as")
    if [ -z "$AS_DATA" ]; then
        AS_NAME="Unknown"
    else
        AS_NAME=$(echo "$AS_DATA" | cut -c1-25) # Ограничиваем длину для таблицы
    fi

    # 1. Проверка Пинга и получение времени ответа
    PING_OUT=$(ping -c 1 -W 1 "$DOMAIN" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        PING_RES="\e[1;32mUP\e[0m"
        LATENCY=$(echo "$PING_OUT" | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1 " ms"}')
    else
        PING_RES="\e[1;31mDOWN\e[0m"
        LATENCY="---"
    fi

    # 2. Проверка SSL (порт 443)
    END_DATE_STR=$(timeout 3 openssl s_client -servername "$DOMAIN" -connect "$DOMAIN":443 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)

    if [ -z "$END_DATE_STR" ]; then
        SSL_DAYS="N/A"
        STATUS="\e[1;31mSSL ERROR\e[0m"
    else
        # Расчет дней до истечения
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

    # Вывод данных в таблицу
    printf "%-18s %-20b %-12s %-10s %-25s %b\n" "$DOMAIN" "$PING_RES" "$LATENCY" "$SSL_DAYS" "$AS_NAME" "$STATUS"
done
