curl -o filename https://example.com/path/to/file

echo "label: gpt" | sfdisk /dev/sdX --wipe always
# Create boot partition
echo ",1G,U" | sfdisk /dev/sdX
# Create root partition using the rest of the space
echo ",," | sfdisk /dev/sdX

# Before chroot
loadkeys fi
lsblk

fdisk /dev/nvme0

Delete old:
	d
	d
	p

Boot:
	g
	n
	
	
	+1G
	t
	1

Root:
	n
	
	
	
	t
	w

lsblk
fdisk -l

cryptsetup -y -v --type luks2 luksFormat /dev/nvme0
cryptsetup luksOpen /dev/nvme0n1p* cryptlvm

pvcreate /dev/mapper/cryptlvm
vgcreate vg /dev/mapper/cryptlvm
lvcreate -n lv -L 64G lvswap
lvcreate -n lv -l 100%FREE lvroot

mkfs.xfs /dev/vg/lvroot

swapon /dev/vg/lvswap
mount /dev/vg/lvroot /mnt
mkdir -p /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot

pacstrap -K /mnt \
	base linux linux-firmware sof-firmware lvm2 dosfstools base-devel efibootmgr xfsprogs \
	openssh git nano sudo networkmanager xdg-desktop-portal xdg-desktop-portal-gtk tpm2-tss xorg-xwayland \
	amd-ucode intel-ucode pipewire plasma plasma-meta sddm tilix kate firefox
	
genfstab /mnt > /mnt/etc/fstab
arch-chroot /mnt

# After chroot
ln -sf /usr/share/zoneinfo/Europe/Helsinki /etc/localtime
hwclock --systohc
nano /etc/locale.gen
locale-gen
nano /etc/locale.conf (LANG=en_US.UTF-8)
echo "KEYMAP=fi" > /etc/vconsole.conf
echo "archie0" > /etc/hostname

nano /etc/hosts
::1 localhost
127.0.0.1 localhost
127.0.1.1 arch0.smairo arch0

passwd
useradd -m -G wheel -s /bin/bash smairo 
passwd smairo 
EDITOR=nano visudo (uncomment %wheel)

systemctl enable NetworkManager.service

echo "options nvidia_drm modeset=1 fbdev=1" > /etc/modprobe.d/nvidia.conf

bootctl --path=/boot install
nano /boot/loader/loader.conf
systemd-cryptenroll --tpm2-device=auto /dev/nvme0n1p2
blkid -s UUID -o value /dev/nvme0n1p2 > /etc/crypttab.initramfs
blkid -s UUID -o value /dev/nvme0n1p2 > /boot/loader/entries/arch.conf

nano /etc/mkinitcpio.conf
HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt lvm2 filesystems fsck)

nano /etc/crypttab.initramfs
cryptlvm UUID=d3df7711-3554-433a-bb5a-606c8e59a11b none luks,tpm2-device=auto

pacman -Rns xf86-video-nouveau

bootctl update
mkinitcpio -p linux
exit
umount -R /mnt
reboot

# Post reboot
(KZones)
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
yay -S vivaldi
yay -S jetbrains-toolbox
yay -S spotify
