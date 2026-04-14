#!/bin/bash

# Список доменов
DOMAINS=(
    "new.tv.team" "new.tvteam.pro" "new.tvteam.eu" "speed.tv.team" "speed.tvteam.pro"
    "speed.tv.in" "speed.hls.ga" "webplayer.tv.in" "tv.team" "tvteam.eu" "team.ga"
    "speed.tvteam.eu" "wiki.tv.in" "rus.tvtm.one" "tvtm.one" "rus.hls.ga"
     "epg.team" "rus.epg.team" "tv.team" "speed.team.ga" "1.1usd.tv"
    "2.1usd.tv" "tvteam.pro" "de.1usd.tv" "ua.1usd.tv" "troya.tv" "troya.info" "chat.tv.in"
    "speed.troya.tv" "speed.troya.info" "speed.tvteam.eu"
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
    printf "%-18s %-20b %-12s %-10s %b\n" "$DOMAIN" "$PING_RES" "$LATENCY" "$SSL_DAYS" "$STATUS"
done
