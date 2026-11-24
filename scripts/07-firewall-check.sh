#!/bin/bash
# Этап 07: действующие и постоянные правила firewalld.

source "$(dirname "${BASH_SOURCE[0]}")/lib/check.sh" || exit 2
require_root

# firewall-cmd может вывести значения в другом порядке.
check_list() {
    local description=$1 expected=$2 values
    shift 2
    if values=$(firewall-cmd "$@"); then
        values=$(printf '%s\n' "$values" | tr '[:space:]' '\n' | sed '/^$/d' | LC_ALL=C sort | paste -sd ' ' -)
        check_eq "$description" "$expected" "$values"
    else
        fail "$description: запрошенные правила недоступны"
    fi
}

section "Служба"
check "firewalld активен" systemctl is-active --quiet firewalld
check "firewalld включён в автозагрузку" systemctl is-enabled --quiet firewalld
check "Постоянная конфигурация корректна" firewall-cmd --check-config

for mode in runtime permanent; do
    options=()
    if [[ $mode == permanent ]]; then
        options=(--permanent)
        section "Постоянные правила"
    else
        section "Действующие правила"
    fi

    for entry in 'adminos|10.0.1.0/24|ssh|' 'zabbix-agent|10.0.1.34||11050/tcp' 'kln-agent|10.0.12.202||13000/tcp 14000/tcp 15000/udp'; do
        IFS='|' read -r zone source service ports <<< "$entry"
        zone_options=("${options[@]}" "--zone=$zone")
        check_list "$zone: источники" "$source" "${zone_options[@]}" --list-sources
        check_list "$zone: службы" "$service" "${zone_options[@]}" --list-services
        check_list "$zone: порты" "$ports" "${zone_options[@]}" --list-ports
        check_list "$zone: интерфейсы" "" "${zone_options[@]}" --list-interfaces
        check_list "$zone: rich rules" "" "${zone_options[@]}" --list-rich-rules
        if zone_config=$(firewall-cmd "${zone_options[@]}" --list-all); then
            target=$(awk '$1 == "target:" { print $2; exit }' <<< "$zone_config")
            check_eq "$zone: target" "default" "$target"
        else
            fail "$zone: не удалось прочитать параметры зоны"
        fi
    done

    firewall-cmd "${options[@]}" --zone=public --query-service=ssh >/dev/null
    check_eq "public: служба SSH отключена (код 1)" "1" "$?"
    firewall-cmd "${options[@]}" --zone=public --query-port=22/tcp >/dev/null
    check_eq "public: порт 22/tcp не открыт напрямую (код 1)" "1" "$?"
done
printf '\nСетевую доступность проверяйте отдельно с клиента соответствующей подсети.\n'

summary
