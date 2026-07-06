#!/usr/bin/env bash
# License: GPL-3.0-or-later

iso_name="oni-sys-os"
iso_label="ONI_SYS_$(date +%Y%m)"
iso_publisher="Oni-Sys OS Architect <https://github.com>"
iso_application="Oni-Sys OS Live Boot Disc"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')

# ИСПРАВЛЕНО: Используем современный, единый режим загрузки флешки через GRUB
bootmodes=('uefi.grub')

arch="x86_64"
pacman_conf="pacman.conf"

file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/usr/local/bin/oni-autostart-installer.fish"]="0:0:755"
)
