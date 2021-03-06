#!/bin/bash -
# libguestfs
# Copyright (C) 2013 Red Hat Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

# The basic plan comes from:
# http://honk.sigxcpu.org/con/Preseeding_Debian_virtual_machines_with_virt_install.html
# https://wiki.debian.org/DebianInstaller/Preseed

set -e
set -x

# Some configuration.
export http_proxy=http://cache.home.annexia.org:3128
export https_proxy=$http_proxy
export ftp_proxy=$http_proxy
location=http://ftp.uk.debian.org/debian/dists/squeeze/main/installer-amd64

# Make sure it's being run from the correct directory.
if [ ! -f debian-6.preseed ]; then
    echo "You are running this script from the wrong directory."
    exit 1
fi

pwd=`pwd`

# Note that the injected file must be called "/preseed.cfg" in order
# for d-i to pick it up.
sed -e "s,@CACHE@,$http_proxy,g" < debian-6.preseed > preseed.cfg

virsh undefine tmpd6 ||:
rm -f debian-6 debian-6.old

virt-install \
    --name tmpd6 \
    --ram=1024 \
    --os-type=linux --os-variant=debiansqueeze \
    --initrd-inject=$pwd/preseed.cfg \
    --extra-args="auto console=tty0 console=ttyS0,115200" \
    --disk=$pwd/debian-6,size=4 \
    --location=$location \
    --nographics \
    --noreboot
# The virt-install command should exit after complete installation.
# Remove the guest, we don't want it to be defined in libvirt.
virsh undefine tmpd6

rm preseed.cfg

# Sysprep (removes logfiles and so on).
virt-sysprep -a debian-6

# Sparsify.
mv debian-6 debian-6.old
virt-sparsify debian-6.old debian-6
rm debian-6.old

# Compress.
rm -f debian-6.xz
xz --best --block-size=$((16*1024*1024)) debian-6

# Result:
ls -lh debian-6.xz
