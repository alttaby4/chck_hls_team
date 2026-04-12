#!/bin/bash

# Список доменов
DOMAINS=(
    "1.tvtm.one" "2.tvtm.one" "3.tvtm.one" "4.tvtm.one" "5.tvtm.one"
    "6.tvtm.one" "7.tvtm.one" "8.tvtm.one" "9.tvtm.one" "10.tvtm.one"
    "11.tvtm.one" "12.tvtm.one" "13.tvtm.one" "14.tvtm.one" "15.tvtm.one"
    "16.tvtm.one" "17.tvtm.one" "hk.tvtm.one" "de.tvtm.one" "ru.tvtm.one"
    "ru2.tvtm.one" "ru3.tvtm.one" "ru4.tvtm.one" "ru5.tvtm.one" "ru6.tvtm.one"
    "ru7.tvtm.one" "ua.tvtm.one" "ua2.tvtm.one" "nl.tvtm.one" "nl2.tvtm.one" "pl.tvtm.one"
)

# Заголовки таблицы
echo -e "\e[1;34m%-18s %-10s %-12s %-10s %-15s\e[0m" "DOMAIN" "PING" "LATENCY" "SSL DAYS" "STATUS"
echo "--------------------------------------------------------------------------------"

for DOMAIN in "${DOMAINS[@]}"; do
    # 1. Проверка Пинга и получение времени ответа
    PING_OUT=$(ping -c 1 -W 1 "$DOMAIN" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        PING_RES="\e[1;32mUP\e[0m"
        # Извлекаем время из строки "time=45.2 ms"
        LATENCY=$(echo "$PING_OUT" | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1 " ms"}')
    else
        PING_RES="\e[1;31mDOWN\e[0m"
        LATENCY="---"
    fi

    # 2. Проверка SSL (порт 443)
    END_DATE_STR=$(timeout 2 openssl s_client -servername "$DOMAIN" -connect "$DOMAIN":443 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)

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
        elif [ "$DAYS_LEFT" -le 14 ]; then
            STATUS="\e[1;33mRENEW SOON\e[0m"
        else
            STATUS="\e[1;32mOK\e[0m"
        fi
    fi

    # Вывод данных в таблицу
    printf "%-18s %-20b %-12s %-10s %b\n" "$DOMAIN" "$PING_RES" "$LATENCY" "$SSL_DAYS" "$STATUS"
done
