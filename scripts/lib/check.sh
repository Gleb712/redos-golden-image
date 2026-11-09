#!/bin/bash
# Общие функции для скриптов проверки этапов.
# Подключается через source, отдельно не запускается.

# Цвета включаем, только если вывод идет в терминал:
# в файле escape-коды превратились бы в мусор.
if [[ -t 1 ]]; then
    GREEN=$'\e[32m'
    RED=$'\e[31m'
    BOLD=$'\e[1m'
    RESET=$'\e[0m'
else
    GREEN='' RED='' BOLD='' RESET=''
fi

PASSED=0
FAILED=0

# Заголовок группы проверок
section() {
    printf '\n%s== %s ==%s\n' "$BOLD" "$1" "$RESET"
}

pass() {
    printf '[%sSUCCESS%s] %s\n' "$GREEN" "$RESET" "$1"
    PASSED=$((PASSED + 1))
}

fail() {
    printf '[%sFAILED%s]  %s\n' "$RED" "$RESET" "$1"
    FAILED=$((FAILED + 1))
}

# check "описание" команда [аргументы...]
# Успех, если команда завершилась с кодом 0.
check() {
    local description=$1
    shift
    if "$@" >/dev/null 2>&1; then
        pass "$description"
    else
        fail "$description"
    fi
}

# check_not "описание" команда [аргументы...]
# Успех, если команда завершилась с ошибкой.
check_not() {
    local description=$1
    shift
    if "$@" >/dev/null 2>&1; then
        fail "$description"
    else
        pass "$description"
    fi
}

# check_eq "описание" "ожидаемое" "фактическое"
check_eq() {
    local description=$1 expected=$2 actual=$3
    if [[ "$actual" == "$expected" ]]; then
        pass "$description: $actual"
    else
        fail "$description: ожидалось '$expected', получено '$actual'"
    fi
}

# Скрипты проверки читают системные данные, поэтому нужен root
require_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Запустите через sudo: sudo bash $0" >&2
        exit 2
    fi
}

# Итог. Код возврата 0, только если нет ошибок
summary() {
    printf '\n%sИтого:%s %s%d SUCCESS%s, %s%d FAILED%s\n' \
        "$BOLD" "$RESET" "$GREEN" "$PASSED" "$RESET" "$RED" "$FAILED" "$RESET"
    [[ $FAILED -eq 0 ]]
}
