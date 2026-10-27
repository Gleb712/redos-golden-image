   #!/bin/bash
   # Этап 02: проверка установки ОС и разметки диска

   cat /etc/redos-release
   ls /sys/firmware/efi
   lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT
   sudo pvs
   sudo vgs
   sudo lvs
   df -hT
   swapon --show
   lspci -k | grep -A3 -i ethernet
   lspci -k | grep -A3 -i scsi