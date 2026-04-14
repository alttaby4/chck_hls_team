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

# Цвета
BLUE='\e[1;34m'
GREEN='\e[1;32m'
RED='\e[1;31m'
YELLOW='\e[1;33m'
NC='\e[0m'

# Заголовки таблицы (расширенные)
echo -e "${BLUE}%-18s %-8s %-10s %-8s %-12s %-25s${NC}" "DOMAIN" "PING" "LATENCY" "SSL" "ASN" "PROVIDER"
echo "---------------------------------------------------------------------------------------------------"

for DOMAIN in "${DOMAINS[@]}"; do
    # 1. Получаем IP адрес
    IP=$(dig +short "$DOMAIN" | tail -n1)
    
    if [ -z "$IP" ]; then
        printf "%-18s %-8b %-10s %-8s %-12s %-25s\n" "$DOMAIN" "${RED}ERR${NC}" "---" "---" "---" "DNS Resolve Error"
        continue
    fi

    # 2. Проверка Пинга
    PING_OUT=$(ping -c 1 -W 1 "$IP" 2>/dev/null)
    if [ $? -eq 0 ]; then
        PING_RES="${GREEN}UP${NC}"
        LATENCY=$(echo "$PING_OUT" | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1 "ms"}')
    else
        PING_RES="${RED}DOWN${NC}"
        LATENCY="---"
    fi

    # 3. Получение ASN и Провайдера через WHOIS
    # Извлекаем строку с ASN и названием организации
    WHOIS_DATA=$(whois -h whois.radb.net "$IP" 2>/dev/null | grep -E "origin|descr" | head -n 2)
    ASN=$(echo "$WHOIS_DATA" | grep -i "origin" | awk '{print $2}' | head -n1)
    # Если ASN пустой, пробуем другой формат (для некоторых сетей)
    [ -z "$ASN" ] && ASN="N/A"
    
    PROVIDER=$(echo "$WHOIS_DATA" | grep -i "descr" | sed 's/descr://g' | xargs | cut -c1-25)
    [ -z "$PROVIDER" ] && PROVIDER="Unknown"

    # 4. Проверка SSL
    END_DATE_STR=$(timeout 2 openssl s_client -servername "$DOMAIN" -connect "$DOMAIN":443 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
    if [ -z "$END_DATE_STR" ]; then
        SSL_DAYS="${RED}ERR${NC}"
    else
        END_DATE_S=$(date -d "$END_DATE_STR" +%s)
        CURRENT_DATE_S=$(date +%s)
        SSL_DAYS=$(( (END_DATE_S - CURRENT_DATE_S) / 86400 ))
    fi

    # Вывод
    printf "%-18s %-18b %-10s %-18b %-12s %-25s\n" "$DOMAIN" "$PING_RES" "$LATENCY" "$SSL_DAYS" "$ASN" "$PROVIDER"
done
