#!/usr/bin/env bash
# License: GPL-3.0-or-later

iso_name="oni-sys-os"
iso_label="ONI_SYS_$(date +%Y%m)"
iso_publisher="Oni-Sys OS Architect <https://github.com>"
iso_application="Oni-Sys OS Live Boot Disc"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito' 'uefi-ia32.grub.esp' 'uefi-x64.grub.esp' 'uefi-ia32.grub.eltorito' 'uefi-x64.grub.eltorito')
arch="x86_64"
pacman_conf="pacman.conf"

# Задаем права доступа для файлов на живой флешке
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/usr/local/bin/oni-autostart-installer.fish"]="0:0:755"
)
