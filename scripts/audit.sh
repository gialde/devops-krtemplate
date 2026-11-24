
#!/usr/bin/env bash
set -uo pipefail

REMOTE="devops"
FAILED=0
CERT_MIN_DAYS="${CERT_MIN_DAYS:-30}"
CERT_SECONDS=$((CERT_MIN_DAYS * 86400))

check() {
    local description="$1"
    local command="$2"

    printf "%-65s" "$description"

    if ssh -o BatchMode=yes "$REMOTE" "$command" >/dev/null 2>&1; then
        echo "[ OK ]"
    else
        echo "[ FAIL ]"
        FAILED=1
    fi
}

echo "========================================"
echo "       АУДИТ КОНФИГУРАЦИИ СЕРВЕРА"
echo "========================================"

echo
echo "[1] SSH"

check "SSH работает на порту 2222" \
    "test \"\$(sudo /usr/sbin/sshd -T | awk '/^port / {print \$2; exit}')\" = 2222"

check "Вход root запрещён" \
    "sudo /usr/sbin/sshd -T | grep -q '^permitrootlogin no$'"

check "Парольная аутентификация отключена" \
    "sudo /usr/sbin/sshd -T | grep -q '^passwordauthentication no$'"

check "MaxAuthTries меньше 10" \
    "test \"\$(sudo /usr/sbin/sshd -T | awk '/^maxauthtries / {print \$2; exit}')\" -lt 10"

echo
echo "[4] Веб-сервер"

check "Служба Nginx активна" \
    "systemctl is-active --quiet nginx"

check "Конфигурация Nginx корректна" \
    "sudo /usr/sbin/nginx -t"

check "Сертификат действителен ещё минимум ${CERT_MIN_DAYS} дней" \
    "openssl x509 -in /etc/ssl/certs/devops.crt -checkend ${CERT_SECONDS} -noout"

check "Нет файлов o+w, права закрытого ключа равны 600" \
    "test -z \"\$(find /var/www/devops-site -perm -o+w -print)\" && test \"\$(sudo stat -c '%a' /etc/ssl/private/devops.key)\" = 600"

echo
echo "========================================"

if (( FAILED == 0 )); then
    echo "ИТОГ: все проверки пройдены."
    exit 0
else
    echo "ИТОГ: обнаружены ошибки."
    exit 1
fi

