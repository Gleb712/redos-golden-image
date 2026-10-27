# План работ

Шаблон ВМ: RedOS 7.3.7, UEFI, диск 50 ГБ (LVM), VMware Workstation Pro.

Каждый этап выполняется в отдельной ветке и сливается через pull request.

## Порядок работы с этапом

1. Обновить main: `git switch main` и `git pull`.
2. Создать ветку этапа: `git switch -c <ветка>`.
3. Сделать снапшот ВМ с именем `NN-before-<этап>`.
4. Выполнить настройки вручную по SSH. Команды сохранить в `scripts/NN-<этап>.sh`, итоговые конфиги в `configs/`.
5. Выполнить проверки этапа.
6. Отметить выполненные пункты в этом файле, сделать коммит и `git push -u origin <ветка>`.
7. Открыть PR, просмотреть изменения, слить в main, удалить ветку.

## Сводка

| № | Ветка | Этап | Разделы задания | Статус |
|---|---|---|---|--|
| 00 | — | Создание репозитория | - | + |
| 01 | `docs/plan` | План, очистка структуры | - | + |
| 02 | `vm/install` | ВМ и установка ОС с LVM | 1.2, 1.3, 2.1 | + |
| 03 | `base/setup` | Базовая настройка, open-vm-tools | 2.3, 2.9.4 | - |
| 04 | `base/repos` | Репозитории, обновление | 2.5 | - |
| 05 | `security/users` | Пользователи, sudo, политики паролей | 1.6, 2.7.1–2.7.3 | - |
| 06 | `security/ssh` | SSH-ключи, sshd | 2.7.4 | - |
| 07 | `security/firewall` | firewalld, зоны | 2.8 | - |
| 08 | `services/base` | chrony, rsyslog, postfix | 2.9.1–2.9.3 | - |
| 09 | `services/zabbix` | Zabbix agent 2 | 2.9.5–2.9.8 | - |
| 10 | `services/kaspersky` | klnagent, KESL, очистка | 2.10 | - |
| 11 | `network/dns` | DNS, CA-сертификаты | 2.4, 2.6 | - |
| 12 | `system/logs` | История команд, journald, logrotate | 2.11, 2.12 | - |
| 13 | `template/prepare` | Очистка, шаблон, тестовый клон | 2.13, 2.14 | - |

DNS (этап 11) намеренно идёт после установки всех пакетов. Серверы `10.0.1.10/20` доступны только из сети организации, и после переключения DNS ВМ не сможет скачивать пакеты из интернета.

## Этапы

### 01 · docs/plan
- [ ] Добавить план работы над проектом

### 02 · vm/install
- [ ] ВМ: 2 vCPU, 4 ГБ RAM, UEFI, VMXNET3, контроллер LSI Logic SAS или VMware Paravirtual
- [ ] Диск 50 ГБ, VMDK, thin
- [ ] Установка RedOS 7.3.7
- [ ] Разбивка: `/boot/efi` и `/boot` как обычные разделы, остальное в LVM `vg_uvm` (swap, `/`, `/var`, `/home`, `/tmp`, резерв)
- [ ] Проверка: `lsblk`, `vgs`, `lvs`, `df -h`

### 03 · base/setup
- [ ] Имя хоста `uvm-template-01.uvm-group.com`
- [ ] Удалить anaconda и файлы kickstart
- [ ] Отключить floppy
- [ ] Замаскировать upower
- [ ] Установить и включить open-vm-tools

### 04 · base/repos
- [ ] Файлы `RedOS-Base.repo` и `RedOS-Updates.repo`
- [ ] `dnf makecache`, `dnf upgrade`

### 05 · security/users
- [ ] Пользователи `adminos` и `neustroeved`, группа `wheel`, sudo
- [ ] `chage`: 2 / 70 / 7 дней
- [ ] Политика паролей: длина от 12 символов, запрет 3 последних паролей
- [ ] Блокировка пароля root (только после проверки sudo у adminos)

### 06 · security/ssh
- [ ] Ключ `ed25519` с парольной фразой, `ssh-copy-id`
- [ ] Вход по ключу проверен
- [ ] `PasswordAuthentication no`, `PermitRootLogin no`

### 07 · security/firewall
- [ ] Зона `adminos`: ssh из 10.0.1.0/24
- [ ] Зона `zabbix-agent`: 11050/tcp из 10.0.1.34
- [ ] Зона `kln-agent`: 13000/tcp, 14000/tcp, 15000/udp из 10.0.12.202
- [ ] ssh убран из зоны `public` (после проверки доступа)

### 08 · services/base
- [ ] chrony: NTP `uv-sp-dc01.uvm-group.com` (конфиг под chrony 4)
- [ ] rsyslog: фильтры сессий и audit
- [ ] postfix: relayhost `10.0.13.101:25`, алиас root

### 09 · services/zabbix
- [ ] zabbix-agent2: Server, ServerActive, порт 11050, Hostname
- [ ] sudoers для zabbix (исправленный синтаксис)
- [ ] UserParameters: diskstats, chageUser (исправленный скрипт)
- [ ] Скрипт `lld-disks.py`
- [ ] Мониторинг PostgreSQL и pacemaker

### 10 · services/kaspersky
- [ ] klnagent64 16.3: сервер `uv-sp-ksc-02.uvm-group.com`, порты 14000/13000, SSL
- [ ] KESL 12.5: начальная настройка
- [ ] Скрипт очистки и задание cron

### 11 · network/dns
- [ ] `resolv.conf`: search `uvm-group.com`, DNS 10.0.1.10 и 10.0.1.20 (через NetworkManager)
- [ ] CA-сертификаты

### 12 · system/logs
- [ ] История команд в `/etc/bashrc`
- [ ] journald: 50M / 12M
- [ ] logrotate для rsyslog без дублирования стандартного файла

### 13 · template/prepare
- [ ] Очистка: история, tmp, кеш dnf, логи
- [ ] Сброс machine-id и SSH host keys, проверка их перегенерации
- [ ] Выключение, режим шаблона в Workstation
- [ ] Тестовый клон: загрузка, новый machine-id, вход по SSH