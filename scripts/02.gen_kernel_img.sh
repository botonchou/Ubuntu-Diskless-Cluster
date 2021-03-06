#!/bin/bash

function generate_kernel_image() {

  # zooz <jablonskis@gmail.com>
  # a script to create a basic compressed rootfs for diskless nodes 
  # set variables
  # size in megabytes
  rootfs_size="512"

  # create a rootfs file
  dd if=/dev/zero of=rootfs bs=1k count=$(($rootfs_size * 1024))

  # create an ext4 file system
  mkfs.ext4 -m0 -F -L root rootfs

  # create a mount point
  mkdir -p $mount_point

  # mount the newly created file system
  mount -t ext4 -o loop rootfs $mount_point

  # cd into it and create required directory structure
  cd $mount_point && mkdir -p bin boot dev etc home \
  mnt proc root sbin sys usr/{bin,lib} var/{lib,log,run,tmp} \
  var/lib/nfs tmp var/run/netreport var/lock/subsys

  # copy required files into created directories
  cp -ap /etc .
  cp -ap /dev .
  cp -ap /bin .
  cp -ap /sbin .
  #cp -ap /lib .
  module=lib/modules/
  rsync -a /lib . --exclude /$module
  mkdir -p $module
  cp -ap /$module/$(uname -r) $module/
  #cp -ap /$module/3.8.0-29-generic $module/

  cp -ap /var/lib/nfs var/lib
  cp -ap /usr/bin/id usr/bin

  # cd out of the mount point
  cd ..
}

function setup_client_config() {

  # Setup client configuration
  source utils/config.sh
  apply_config client.conf/ $mount_point

  cd $mount_point

  # Copy DNS server ip configuration to rootfs
  mkdir -p run/resolvconf/
  cp /run/resolvconf/resolv.conf run/resolvconf/resolv.conf

  # Create directory needed by ssh daemon
  mkdir var/run/sshd

  # Create Special files needed by "apt-get"
  sudo mkdir -p var/cache/apt/archives/partial
  sudo touch var/cache/apt/archives/lock
  sudo chmod 640 var/cache/apt/archives/lock

  # Create directory needed by rwhod daemon
  mkdir -p var/spool/rwho

  # Disable update-motd when logging in
  mv etc/update-motd.d/ etc/.update-motd.d.backup/

  # NIS Client Settings
  echo '+::::::' >> etc/passwd
  echo '+:::' >> etc/group
  echo '+::::::::' >> etc/shadow
  echo '+:::' >> etc/gshadow

  cd ../
}

# set mount point for the rootfs
mount_point="rootfs-loop"

generate_kernel_image
setup_client_config

# umount the rootfs-loop
umount $mount_point
