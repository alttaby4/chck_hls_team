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

# Проверка наличия необходимых утилит
for cmd in dig whois openssl ping; do
    if ! command -v $cmd &> /dev/null; then
        echo "Ошибка: утилита '$cmd' не установлена. Установите её (sudo apt install dnsutils whois openssl iputils-ping)."
        exit 1
    fi
done

# Заголовки таблицы
echo -e "\e[1;34m%-15s %-15s %-10s %-8s %-10s %-8s %-10s\e[0m" "DOMAIN" "IP ADDR" "ASN" "PING" "LATENCY" "SSL" "STATUS"
echo "----------------------------------------------------------------------------------------------------------"

for DOMAIN in "${DOMAINS[@]}"; do
    # 1. IP адрес
    IP=$(dig +short "$DOMAIN" | tail -n1)
    
    if [ -z "$IP" ]; then
        printf "%-15s %-15s %-10s %-18b %-10s %-8s %b\n" "$DOMAIN" "NO DNS" "---" "\e[1;31mDOWN\e[0m" "---" "---" "\e[1;31mERR\e[0m"
        continue
    fi

    # 2. ASN
    ASN=$(whois -h whois.cymru.com " -v $IP" 2>/dev/null | tail -n1 | awk '{print "AS"$1}')
    [[ "$ASN" == "ASAS" || -z "$ASN" ]] && ASN="---"

    # 3. Пинг и задержка
    PING_OUT=$(ping -c 1 -W 1 "$IP" 2>/dev/null)
    if [ $? -eq 0 ]; then
        PING_RES="\e[1;32mUP\e[0m"
        LATENCY=$(echo "$PING_OUT" | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1 "ms"}')
    else
        PING_RES="\e[1;31mDOWN\e[0m"
        LATENCY="---"
    fi

    # 4. SSL сертификат
    END_DATE_STR=$(timeout 2 openssl s_client -servername "$DOMAIN" -connect "$IP":443 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)

    if [ -z "$END_DATE_STR" ]; then
        SSL_DAYS="N/A"
        STATUS="\e[1;31mERR\e[0m"
    else
        # Конвертация даты
        END_DATE_S=$(date -d "$END_DATE_STR" +%s 2>/dev/null)
        if [ $? -ne 0 ]; then
             SSL_DAYS="?"
             STATUS="DATE ERR"
        else
            CURRENT_DATE_S=$(date +%s)
            DAYS_LEFT=$(( (END_DATE_S - CURRENT_DATE_S) / 86400 ))
            SSL_DAYS="$DAYS_LEFT"

            if [ "$DAYS_LEFT" -le 0 ]; then
                STATUS="\e[1;31mEXP\e[0m"
            elif [ "$DAYS_LEFT" -le 14 ]; then
                STATUS="\e[1;33mWARN\e[0m"
            else
                STATUS="\e[1;32mOK\e[0m"
            fi
        fi
    fi

    # Финальный вывод строки
    printf "%-15s %-15s %-10s %-18b %-10s %-8s %b\n" "$DOMAIN" "$IP" "$ASN" "$PING_RES" "$LATENCY" "$SSL_DAYS" "$STATUS"
done
# Конец цикла (тот самый done, который исправляет вашу ошибку)#!/bin/bash

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
echo -e "\e[1;34m%-15s %-15s %-10s %-8s %-10s %-8s %-10s\e[0m" "DOMAIN" "IP ADDR" "ASN" "PING" "LATENCY" "SSL" "STATUS"
echo "----------------------------------------------------------------------------------------------------------"

for DOMAIN in "${DOMAINS[@]}"; do
    # 1. Определение IP адреса (DNS)
    IP=$(dig +short "$DOMAIN" | tail -n1)
    
    if [ -z "$IP" ]; then
        printf "%-15s %-15s %-10s %-18b %-10s %-8s %b\n" "$DOMAIN" "NO DNS" "---" "\e[1;31mDOWN\e[0m" "---" "---" "\e[1;31mERR\e[0m"
        continue
    fi

    # 2. Определение ASN
    ASN=$(whois -h whois.cymru.com " -v $IP" | tail -n1 | awk '{print "AS"$1}')
    [ "$ASN" == "ASAS" ] && ASN="---" # Обработка пустого ответа ASN

    # 3. Проверка Пинга и задержки
    PING_OUT=$(ping -c 1 -W 1 "$IP" 2>/dev/null)
    if [ $? -eq 0 ]; then
        PING_RES="\e[1;32mUP\e[0m"
        LATENCY=$(echo "$PING_OUT" | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1 "ms"}')
    else
        PING_RES="\e[1;31mDOWN\e[0m"
        LATENCY="---"
    fi

    # 4. Проверка SSL сертификата (порт 443)
    END_DATE_STR=$(timeout 2 openssl s_client -servername "$DOMAIN" -connect "$IP":443 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)

    if [ -z "$END_DATE_STR" ]; then
        SSL_DAYS="N/A"
        STATUS="\e[1;31mERR\e[0m"
    else
        # Вычисляем разницу дат
        END_DATE_S=$(date -d "$END_DATE_STR" +%s 2>/dev/null)
        if [ $? -ne 0 ]; then
             SSL_DAYS="?"
             STATUS="DATE ERR"
        else
            CURRENT_DATE_S=$(date +%s)
            DAYS_LEFT=$(( (END_DATE_S - CURRENT_DATE_S) / 86400 ))
            SSL_DAYS="$DAYS_LEFT"

            if [ "$DAYS_LEFT" -le 0 ]; then
                STATUS="\e[1;31mEXP\e[0m"
            elif [ "$DAYS_LEFT" -le 14 ]; then
                STATUS="\e[1;33mWARN\e[0m"
            else
                STATUS="\e[1;32mOK\e[0m"
            fi
        fi
    fi

    # Вывод строки в таблицу
    printf "%-15s %-15s %-10s %-18b %-10s %-8s %b\n" "$DOMAIN" "$IP" "$ASN" "$PING_RES" "$LATENCY" "$SSL_DAYS" "$STATUS"
done#!/bin/bash

# Список доменов для проверки
DOMAINS=(
    "1.hls.ga" "3.hls.ga" "4.hls.ga" "6.hls.ga" "2.hls.ga"
    "5.hls.ga" "7.hls.ga" "11.hls.ga" "12.hls.ga" "10.hls.ga"
    "9.hls.ga" "8.hls.ga" "13.hls.ga" "16.hls.ga" "hk.hls.ga"
    "de.hls.ga" "15.hls.ga" "14.hls.ga" "ru.hls.ga" "ru2.hls.ga"
    "ru3.hls.ga" "nl.hls.ga" "nl2.hls.ga" "ru7.hls.ga" "ua.hls.ga"
    "ua2.hls.ga" "ru4.hls.ga" "ru5.hls.ga" "ru6.hls.ga" "17.hls.ga" "pl.hls.ga"
)

# Заголовки таблицы (с расширенными колонками под IP и ASN)
echo -e "\e[1;34m%-15s %-15s %-10s %-8s %-10s %-8s %-10s\e[0m" "DOMAIN" "IP ADDR" "ASN" "PING" "LATENCY" "SSL" "STATUS"
echo "----------------------------------------------------------------------------------------------------------"

for DOMAIN in "${DOMAINS[@]}"; do
    # 1. Определение IP адреса
    IP=$(dig +short "$DOMAIN" | tail -n1)
    
    if [ -z "$IP" ]; then
        printf "%-15s %-15s %-10s %-20b %-20s %s\n" "$DOMAIN" "NO DNS" "---" "\e[1;31mDOWN\e[0m" "---" "ERR"
        continue
    fi

    # 2. Определение ASN (Автономная система)
    ASN=$(whois -h whois.cymru.com " -v $IP" | tail -n1 | awk '{print "AS"$1}')

    # 3. Проверка Пинга и задержки
    PING_OUT=$(ping -c 1 -W 1 "$IP" 2>/dev/null)
    if [ $? -eq 0 ]; then
        PING_RES="\e[1;32mUP\e[0m"
        LATENCY=$(echo "$PING_OUT" | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1 "ms"}')
    else
        PING_RES="\e[1;31mDOWN\e[0m"
        LATENCY="---"
    fi

    # 4. Проверка SSL сертификата (порт 443)
    END_DATE_STR=$(timeout 2 openssl s_client -servername "$DOMAIN" -connect "$IP":443 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)

    if [ -z "$END_DATE_STR" ]; then
        SSL_DAYS="N/A"
        STATUS="\e[1;31mERR\e[0m"
    else
        END_DATE_S=$(date -d "$END_DATE_STR" +%s)
        CURRENT_DATE_S=$(date +%s)
        DAYS_LEFT=$(( (END_DATE_S - CURRENT_DATE_S) / 86400 ))
        SSL_DAYS="$DAYS_LEFT"

        if [ "$DAYS_LEFT" -le 0 ]; then
            STATUS="\e[1;31mEXP\e[0m"
        elif [ "$DAYS_LEFT" -le 14 ]; then
            STATUS="\e[1;33mWARN\e[0m"
        else
            STATUS="\e[1;32mOK\e[0m"
        fi
    fi

    # Итоговый вывод в таблицу
    printf "%-15s %-15s %-10s %-18b %-10s %-8s %b\n" "$DOMAIN" "$IP" "$ASN" "$PING_RES" "$LATENCY" "$SSL_DAYS" "$STATUS"
done#!/bin/bash

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
        elif [ "$DAYS_LEFT" -le 4 ]; then
            STATUS="\e[1;33mRENEW SOON\e[0m"
        else
            STATUS="\e[1;32mOK\e[0m"
        fi
    fi

    # Вывод данных в таблицу
    printf "%-18s %-20b %-12s %-10s %b\n" "$DOMAIN" "$PING_RES" "$LATENCY" "$SSL_DAYS" "$STATUS"
done
