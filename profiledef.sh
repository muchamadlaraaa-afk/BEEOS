#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="BEEOS"
iso_publisher="BEEOS Builder <https://github.com/muchamadlaraaa-afk/BEEOS>"
iso_application="BEEOS Glassmorphic Live OS Image"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito' 'uefi-ia32.grub.esp' 'uefi-x64.grub.esp' 'uefi-ia32.grub.eltorito' 'uefi-x64.grub.eltorito')
arch="x86_64"
pacman_conf="pacman.conf"

# Directory permissions mapping inside the live environment ISO
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/etc/gshadow"]="0:0:400"
  ["/etc/skel/.local/bin/first-boot-setup.sh"]="0:0:755"
)
