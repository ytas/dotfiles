#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# Arch post-chroot setup script
# Intended to be executed INSIDE arch-chroot.
#
# This script:
# - Sets timezone and locale
# - Configures hostname
# - Installs and configures systemd-boot
# - Enables NetworkManager
# - Creates a user with sudo privileges
#
# Secure Boot (sbctl) is NOT handled here.
# NVIDIA and Hyprland are NOT installed here.
# ------------------------------------------------------------

read -rp "Enter hostname: " HOSTNAME
read -rp "Enter username: " USERNAME

echo "=== Setting timezone ==="
ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
hwclock --systohc

echo "=== Configuring locale ==="
sed -i 's/^#\s*\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "=== Setting hostname ==="
echo "$HOSTNAME" > /etc/hostname

echo "=== Enabling NetworkManager ==="
systemctl enable NetworkManager

echo "=== Installing systemd-boot ==="
bootctl install

echo "=== Detecting root partition UUID ==="
ROOT_DEVICE=$(findmnt -n -o SOURCE /)
ROOT_UUID=$(blkid -s UUID -o value "$ROOT_DEVICE")

echo "=== Configuring boot loader ==="
cat > /boot/loader/loader.conf <<EOF
default arch
timeout 3
editor no
EOF

cat > /boot/loader/entries/arch.conf <<EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=UUID=${ROOT_UUID} rw
EOF

echo "=== Setting root password ==="
passwd

echo "=== Creating user ==="
useradd -m -G wheel -s /bin/bash "$USERNAME"
passwd "$USERNAME"

echo "=== Enabling sudo for wheel group ==="
sed -i 's/^#\s*\(%wheel ALL=(ALL:ALL) ALL\)/\1/' /etc/sudoers

echo
echo "=== Post-chroot setup completed successfully ==="
echo "You may now exit chroot, unmount, and reboot."
