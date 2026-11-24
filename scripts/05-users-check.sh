#!/bin/bash
# Этап 05: локальные администраторы, sudo и политика паролей.

source "$(dirname "${BASH_SOURCE[0]}")/lib/check.sh" || exit 2
require_root

section "Локальные администраторы"
check "Конфигурация sudo корректна" visudo -c
for account in adminos neustroeved; do
    check "Локальный пользователь $account существует" getent -s files passwd "$account"
    check "$account входит в wheel" bash -c 'id -nG "$1" | tr " " "\n" | grep -Fxq wheel' bash "$account"
    check "$account может выполнить id от root через sudo" sudo -l -U "$account" -u root /usr/bin/id
    password_status=$(LC_ALL=C passwd -S "$account" 2>/dev/null | awk '{print $2}')
    case "$password_status" in
        P|PS) pass "$account: пароль разблокирован" ;;
        *) fail "$account: ожидался статус P или PS, получено ${password_status:-нет данных}" ;;
    esac
    ages=$(getent -s files shadow "$account" | awk -F: '{print $4 "/" $5 "/" $6}')
    check_eq "$account: минимум / максимум / предупреждение" "2/70/7" "$ages"
done

section "Политика паролей"
check "Конфигурация authselect действительна" authselect check
check "Длина пароля не менее 12 символов по конфигурации UVM"     grep -Eq '^[[:space:]]*minlen[[:space:]]*=[[:space:]]*12([[:space:]]*(#.*)?)?$' /etc/security/pwquality.conf
for credit in dcredit ucredit lcredit ocredit; do
    check "Параметр $credit равен 0"         grep -Eq "^[[:space:]]*$credit[[:space:]]*=[[:space:]]*0([[:space:]]*(#.*)?)?$" /etc/security/pwquality.conf
done
check "Глубина истории равна 3"     grep -Eq '^[[:space:]]*remember[[:space:]]*=[[:space:]]*3([[:space:]]*(#.*)?)?$' /etc/security/pwhistory.conf
for policy in pwquality pwhistory; do
    check "$policy: проверка применяется при смене пароля от root"         grep -Eq '^[[:space:]]*enforce_for_root([[:space:]]*(#.*)?)?$' "/etc/security/$policy.conf"
done
for pam_file in /etc/pam.d/system-auth /etc/pam.d/password-auth; do
    check "$pam_file: подключён pam_pwquality" grep -Eq '^[[:space:]]*password[[:space:]]+[^[:space:]]+[[:space:]]+pam_pwquality\.so([[:space:]]|$)' "$pam_file"
    check "$pam_file: подключён pam_pwhistory" grep -Eq '^[[:space:]]*password[[:space:]]+[^[:space:]]+[[:space:]]+pam_pwhistory\.so[[:space:]]+.*use_authtok' "$pam_file"
done

section "Пароль root"
root_status=$(LC_ALL=C passwd -S root 2>/dev/null | awk '{print $2}')
case "$root_status" in
    L|LK) pass "Пароль root заблокирован ($root_status)" ;;
    *) fail "Пароль root: ожидался L или LK, получено ${root_status:-нет данных}" ;;
esac

summary
