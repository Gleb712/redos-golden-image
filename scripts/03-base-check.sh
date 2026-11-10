#!/bin/bash
# Этап 03: проверка базовой настройки системы.
# Запуск на ВМ: sudo bash scripts/03-base-check.sh

source "$(dirname "${BASH_SOURCE[0]}")/lib/check.sh"
require_root

section "Имя хоста"
check_eq "Имя в /etc/hostname" "uvm-template-01.uvm-group.com" "$(cat /etc/hostname)"
check_eq "Текущее имя" "uvm-template-01.uvm-group.com" "$(hostname)"

section "Следы установщика"
check_not "Пакет anaconda не установлен" rpm -q anaconda
for f in anaconda-ks.cfg original-ks.cfg ks-post-copy.log ks-pre.log ks-post-exc.log ks-post.log; do
    check_not "/root/$f отсутствует" test -e "/root/$f"
done
check_not "/var/log/anaconda удален" test -e /var/log/anaconda

section "Floppy"
check_not "Модуль floppy не загружен" grep -qw floppy /proc/modules
check "Blacklist floppy настроен" grep -qx "blacklist floppy" /etc/modprobe.d/blacklist-floppy.conf

section "UPower"
check_eq "upower.service" "masked" "$(systemctl is-enabled upower.service 2>/dev/null)"

section "open-vm-tools"
check "Пакет open-vm-tools установлен" rpm -q open-vm-tools
check_eq "vmtoolsd в автозапуске" "enabled" "$(systemctl is-enabled vmtoolsd)"
check_eq "vmtoolsd запущен" "active" "$(systemctl is-active vmtoolsd)"

summary