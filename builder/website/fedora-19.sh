#!/bin/bash -
# virt-builder
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

set -e
set -x

# Some configuration.
export http_proxy=http://cache.home.annexia.org:3128
export https_proxy=$http_proxy
export ftp_proxy=$http_proxy
tree=http://mirror.bytemark.co.uk/fedora/linux/releases/19/Fedora/x86_64/os/

# Currently you have to run this script as root.
if [ `id -u` -ne 0 ]; then
    echo "You have to run this script as root."
    exit 1
fi

# Make sure it's being run from the correct directory.
if [ ! -f fedora-19.ks ]; then
    echo "You are running this script from the wrong directory."
    exit 1
fi

pwd=`pwd`

virsh undefine tmpf19 ||:
rm -f fedora-19 fedora-19.old

virt-install \
    --name=tmpf19 \
    --ram 2048 \
    --cpu=host --vcpus=2 \
    --os-type=linux --os-variant=fedora19 \
    --initrd-inject=$pwd/fedora-19.ks \
    --extra-args="ks=file:/fedora-19.ks console=tty0 console=ttyS0,115200 proxy=$http_proxy" \
    --disk $pwd/fedora-19,size=4 \
    --location=$tree \
    --nographics \
    --noreboot
# The virt-install command should exit after complete installation.
# Remove the guest, we don't want it to be defined in libvirt.
virsh undefine tmpf19

# Sysprep (removes logfiles and so on).
# Note this also touches /.autorelabel so the further installation
# changes that we make will be labelled properly at first boot.
virt-sysprep -a fedora-19

# Sparsify.
mv fedora-19 fedora-19.old
virt-sparsify fedora-19.old fedora-19
rm fedora-19.old

# Compress.
rm -f fedora-19.xz
xz --best --block-size=16777216 fedora-19

# Result:
ls -lh fedora-19.xz
