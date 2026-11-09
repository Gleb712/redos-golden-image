#!/bin/bash
# Этап 02: проверка установки ОС и разметки диска.
# Запуск на ВМ: sudo bash scripts/02-install-check.sh

source "$(dirname "${BASH_SOURCE[0]}")/lib/check.sh"
require_root

# Размер тома в GiB
lv_size() {
    lvs --noheadings --units g --nosuffix -o lv_size "vg_uvm/$1" 2>/dev/null | tr -d ' <'
}

section "Операционная система"
check "Версия RedOS 7.3.7" grep -q "(7.3.7)" /etc/redos-release
check "Загрузка в режиме UEFI" test -d /sys/firmware/efi

section "Диск и разделы"
check_eq "Размер диска sda" "50G" "$(lsblk -dno SIZE /dev/sda | tr -d ' ')"
check_eq "Таблица разделов" "gpt" "$(lsblk -dno PTTYPE /dev/sda)"
check_eq "/boot/efi: устройство" "/dev/sda1" "$(findmnt -no SOURCE /boot/efi)"
check_eq "/boot/efi: файловая система" "vfat" "$(findmnt -no FSTYPE /boot/efi)"
check_eq "/boot: устройство (вне LVM)" "/dev/sda2" "$(findmnt -no SOURCE /boot)"
check_eq "/boot: файловая система" "ext4" "$(findmnt -no FSTYPE /boot)"

section "LVM"
check "Группа томов vg_uvm существует" vgs vg_uvm

# Формат: том:точка_монтирования:размер_GiB
volumes=(
    "lv_root:/:15.00"
    "lv_var:/var:15.00"
    "lv_home:/home:10.00"
    "lv_tmp:/tmp:2.00"
)
for item in "${volumes[@]}"; do
    IFS=: read -r lv mountpoint size <<< "$item"
    check_eq "$lv: размер, GiB" "$size" "$(lv_size "$lv")"
    check_eq "$lv: смонтирован в $mountpoint" "/dev/mapper/vg_uvm-$lv" "$(findmnt -no SOURCE "$mountpoint")"
    check_eq "$lv: файловая система" "ext4" "$(findmnt -no FSTYPE "$mountpoint")"
done

check_eq "lv_swap: размер, GiB" "4.00" "$(lv_size lv_swap)"
check_eq "Swap активен" "4G" "$(swapon --noheadings --show=SIZE | tr -d ' ')"

vfree=$(vgs --noheadings --units g --nosuffix -o vg_free vg_uvm | tr -d ' <')
check "Резерв в vg_uvm не меньше 2 GiB: $vfree" awk -v f="$vfree" 'BEGIN { exit !(f >= 2) }'

section "Виртуальное оборудование"
iface=$(ip -o route show default | awk '{ print $5; exit }')
nic_driver=$(readlink -f "/sys/class/net/$iface/device/driver" 2>/dev/null)
check_eq "Драйвер сети ($iface)" "vmxnet3" "${nic_driver##*/}"
check "Драйвер диска vmw_pvscsi загружен" grep -qw vmw_pvscsi /proc/modules

summary