#!/bin/bash
# Этап 06: параметры SSH и наличие ключа администратора.

source "$(dirname "${BASH_SOURCE[0]}")/lib/check.sh" || exit 2
require_root

section "Служба SSH"
check "Служба sshd активна" systemctl is-active --quiet sshd
check "Синтаксис конфигурации sshd корректен" /usr/sbin/sshd -t

section "Действующая конфигурация SSH"
if ssh_settings=$(/usr/sbin/sshd -T); then
    for rule in permitrootlogin:no passwordauthentication:no kbdinteractiveauthentication:no pubkeyauthentication:yes; do
        IFS=: read -r setting expected <<< "$rule"
        actual=$(awk -v key="$setting" 'tolower($1) == key { print tolower($2); exit }' <<< "$ssh_settings")
        check_eq "$setting" "$expected" "$actual"
    done
else
    fail "Не удалось прочитать конфигурацию sshd"
fi

section "Публичный ключ администратора"
admin_home=$(getent passwd adminos | cut -d: -f6)
if [[ -n $admin_home ]]; then
    key_file="$admin_home/.ssh/authorized_keys"
    check "В authorized_keys указан ключ ED25519" grep -Eq '^ssh-ed25519[[:space:]]+[A-Za-z0-9+/=]+([[:space:]]|$)' "$key_file"
    check "OpenSSH читает файл authorized_keys" ssh-keygen -lf "$key_file"
    check_eq "Владелец и права каталога .ssh" "adminos:700" "$(stat -c '%U:%a' "$admin_home/.ssh" 2>/dev/null)"
    check_eq "Владелец и права authorized_keys" "adminos:600" "$(stat -c '%U:%a' "$key_file" 2>/dev/null)"
else
    fail "Домашний каталог adminos не найден"
fi
printf '\nВход по ключу и парольная фраза проверяются на клиенте.\n'

summary
