#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="archlinux-glassmorphic-kde"
iso_publisher="Custom OS Builder <https://github.com/google/antigravity>"
iso_application="Custom Glassmorphic OS Live Image"
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
