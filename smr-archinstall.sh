#!/bin/bash
# Loop through all the positional parameters
while [[ $# -gt 0 ]]; do
    case $1 in
        -drive)
            drive_val="$2"
            shift 2 
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

#echo $drive_val
#fdisk -l /dev/$drive_val
echo "label: gpt" | sfdisk /dev/$drive_val --wipe always
echo ",1G,U" | sfdisk /dev/$drive_val
echo ",," | sfdisk /dev/$drive_val
cryptsetup -y -v --type luks2 luksFormat /dev/$drive_valp2
cryptsetup luksOpen /dev/$drive_valp2 cryptlvm

pvcreate /dev/mapper/cryptlvm
vgcreate vg /dev/mapper/cryptlvm
lvcreate -n lv -L 64G lvswap
lvcreate -n lv -l 100%FREE lvroot

mkfs.xfs /dev/vg/lvroot

swapon /dev/vg/lvswap
mount /dev/vg/lvroot /mnt
mkdir -p /mnt/boot
mount /dev/$drive_valp1 /mnt/boot

pacstrap -K /mnt \
	base linux linux-firmware sof-firmware lvm2 dosfstools base-devel efibootmgr xfsprogs \
	openssh git nano sudo networkmanager xdg-desktop-portal xdg-desktop-portal-gtk tpm2-tss xorg-xwayland \
	amd-ucode intel-ucode pipewire plasma plasma-meta sddm tilix kate firefox
	
genfstab /mnt > /mnt/etc/fstab
