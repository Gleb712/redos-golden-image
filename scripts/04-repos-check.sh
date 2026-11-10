#!/bin/bash
# Этап 04: проверка репозиториев и обновления.
# Запуск на ВМ: sudo bash scripts/04-repos-check.sh

source "$(dirname "${BASH_SOURCE[0]}")/lib/check.sh"
require_root

REPO_DIR=/etc/yum.repos.d
REPO_FILES="RedOS-Base.repo RedOS-Updates.repo RedOS-kernels6.repo"

section "Файлы репозиториев"
check "Резервная копия старых .repo не пуста" test -n "$(ls -A "$REPO_DIR/backup" 2>/dev/null)"
check_eq "Активные .repo" "$REPO_FILES" "$(cd "$REPO_DIR" && ls *.repo | LC_ALL=C sort | xargs)"
for f in $REPO_FILES; do
    check_eq "$f: права" "644 root:root" "$(stat -c '%a %U:%G' "$REPO_DIR/$f")"
    check "$f: проверка подписи включена" grep -qx "gpgcheck=1" "$REPO_DIR/$f"
done
check "Ключ RPM-GPG-KEY-RED-SOFT на месте" test -f /etc/pki/rpm-gpg/RPM-GPG-KEY-RED-SOFT

section "Репозитории dnf"
enabled=$(dnf -q repolist --enabled | awk 'NR > 1 { print $1 }' | sort | xargs)
check_eq "Включенные репозитории" "base kernels6 updates" "$enabled"

section "Обновления"
check "Нет доступных обновлений" dnf -q check-update
latest_kernel=$(rpm -q kernel-lt --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' | sort -V | tail -n 1)
check_eq "Работает последнее установленное ядро" "$latest_kernel" "$(uname -r)"

summary
