#!/usr/bin/env bash
# Доставка статического ресурса на devops-vm
# Использование: scripts/deploy.sh [--dry-run]

set -euo pipefail

REMOTE="devops"
REMOTE_DIR="/var/www/devops-site"
SITE_URL="https://devops.local"
CA_CERT="${HOME}/devops.crt"

REPO_ROOT="$(git rev-parse --show-toplevel)"
LOCAL_DIR="${REPO_ROOT}/site/"

# 1. Разбор аргумента --dry-run
DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=1
elif [[ -n "${1:-}" ]]; then
    echo "Неизвестный аргумент: $1" >&2
    echo "Использование: $0 [--dry-run]" >&2
    exit 1
fi

# 2. Проверки по требованиям 4 и 5
if [[ ! -f "${LOCAL_DIR}index.html" ]]; then
    echo "ОШИБКА: файл ${LOCAL_DIR}index.html отсутствует. Доставка отменена." >&2
    exit 1
fi

cd "${REPO_ROOT}"
if [[ -n "$(git status --porcelain)" ]]; then
    echo "ОШИБКА: в репозитории есть незафиксированные изменения. Доставка отменена." >&2
    exit 1
fi

# 3. Синхронизация каталога
RSYNC_OPTS=(-avz --delete --chmod=D755,F644)
if [[ ${DRY_RUN} -eq 1 ]]; then
    RSYNC_OPTS+=(--dry-run)
fi

rsync "${RSYNC_OPTS[@]}" -e "ssh -o BatchMode=yes -o ConnectTimeout=5" \
    "${LOCAL_DIR}" "${REMOTE}:${REMOTE_DIR}/"

# 4. При --dry-run завершение без проверки доступности
if [[ ${DRY_RUN} -eq 1 ]]; then
    echo "Пробный запуск завершён. Сервер не изменён."
    exit 0
fi

# 5. Проверка доступности
if ! curl -fsS --cacert "${CA_CERT}" -o /dev/null "${SITE_URL}"; then
    echo "ОШИБКА: ресурс ${SITE_URL} недоступен после доставки." >&2
    exit 1
fi

COMMIT_SHORT="$(git rev-parse --short HEAD)"
echo "Доставка выполнена успешно. Коммит: ${COMMIT_SHORT}"
exit 0
