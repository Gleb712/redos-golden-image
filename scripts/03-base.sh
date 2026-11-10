#!/bin/bash
# Этап 03: базовая настройка системы.
# Команды выполняются вручную по SSH, по порядку.

# 1 - Имя хоста
sudo hostnamectl set-hostname uvm-template-01.uvm-group.com
cat /etc/hostname

# 2 - Следы установщика
rpm -qa | grep -i anaconda
sudo ls -la /root/
sudo rm -f /root/anaconda-ks.cfg /root/original-ks.cfg /root/ks-post-copy.log /root/ks-pre.log /root/ks-post-exc.log /root/ks-post.log
sudo rm -rf /var/log/anaconda/

# 3 - Floppy
lsmod | grep floppy
sudo rmmod floppy
echo "blacklist floppy" | sudo tee /etc/modprobe.d/blacklist-floppy.conf
sudo dracut -f

# 4 - UPower
sudo systemctl mask upower.service

# 5 - open-vm-tools
rpm -q open-vm-tools || sudo dnf install -y open-vm-tools
sudo systemctl enable --now vmtoolsd

# 6 - Перезагрузка
sudo reboot