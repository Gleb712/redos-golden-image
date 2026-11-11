#!/bin/bash
# Этап 04: репозитории и обновление системы.
# Команды выполняются вручную по SSH, по порядку.

# 1 - Текущее состояние
ls -l /etc/yum.repos.d/
cat /etc/yum.repos.d/*.repo
dnf repolist
ls -l /etc/pki/rpm-gpg/
rpm -q subscription-manager
rpm -qf /etc/yum.repos.d/RedOS-Base.repo

# 2 - Доступность зеркал
for path in os updates extras/kernels6-73; do
  for mirror in https://repo1.red-soft.ru https://mirror.yandex.ru http://repo.red-soft.ru; do
    url="$mirror/redos/7.3/x86_64/$path"
    code=$(curl -s -o /dev/null -w '%{http_code}' "$url/repodata/repomd.xml")
    echo "$code  $url"
  done
done

# 3 - Резервная копия и установка своих .repo
# (файлы из configs/yum.repos.d скопированы на ВМ через scp)
sudo mkdir -p /etc/yum.repos.d/backup
sudo mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup/
sudo install -m 644 -o root -g root ~/RedOS-*.repo /etc/yum.repos.d/
rm ~/RedOS-*.repo

# 4. Кеш и обновление
sudo dnf clean all
sudo dnf makecache
dnf repolist
sudo dnf upgrade -y

# 5 - Проверка, что rpm не заменил наши .repo при обновлении redos-release
ls -l /etc/yum.repos.d/
sudo reboot
