#!/bin/bash

myhome=/home/dave
mntpt=/nfs/omv # your mount point, if using network drive or external, may be in /media. comment out if saving locally
dest=/nfs/omv/ # destination directory on drive or nfs
destip=192.168.8.98
naslogin=dave@192.168.8.98:/ # NAS login - if no nas, comment this out

bktime=$(date +"%F_%H-%M")
logfile="/home/dave/BackUpErrors-$bktime".log
# sudo -v
if [[ "$EUID" == 0 ]]; then
	echo "While you need sudo for a few things, mount and umount, and a couple of system files"
	echo "this shouldn't be run AS root, so now that you're verified as sudo you can run it"
	echo "again without sudo: ./backup.sh"
	exit 0
fi

# Sending wakeup signal just because it speeds things up...
sudo etherwake -b 00:42:69:00:DD:A6 -i enp2s0

# Checking to see if target is awake...

((count = 2))
while [[ $count -ne 0 ]] ; do
    ping -c 1 $destip >/dev/null;
    rc=$?
    if [[ $rc -eq 0 ]] ; then
        ((count = 1))
    else
        sleep 10
    fi
    ((count = count - 1))
done

if [[ $rc -eq 0 ]] ; then
    echo "NAS is awake, starting backup!"
else
    echo "NAS is dead, Jim!"
fi

mounted    () { findmnt -rno SOURCE,TARGET "$1" >/dev/null;} #path or device

# Mount a NAS
if [ ! -v $naslogin ]; then
    if mounted "$mntpt"; then
        echo "Drive is mounted, here we go!"
    else
        echo "Mounting the NAS... ooh!"
        # sudo mount -t nfs "${naslogin#*@}" $mntpt
        sudo mount -t nfs -o vers=4 192.168.8.98:/ /nfs/omv/
    fi
fi

if [ ! -d $dest ]; then mkdir -p $dest ; fi


rsync -ulrzhv --progress /media/dave/A-F/* /nfs/omv/Big1/BluRay_A-F/
rsync -ulrzhv --progress /media/dave/G-O/G-I/* /nfs/omv/Big1/BluRay_G-O/
rsync -ulrzhv --progress /media/dave/G-O/J-O/* /nfs/omv/Big1/BluRay_G-O/
rsync -ulrzhv --progress /media/dave/P-Z/* /nfs/omv/Big2/BluRay_P-Z/
rsync -ulrzhv --progress /media/dave/4k/* /nfs/omv/Big2/4k/
rsync -ulrzhv --progress /media/dave/DVD-Moobies/TV\ Shows/* /nfs/omv/Big2/TV/
rsync -ulrzhv --progress /media/dave/DVD-Moobies/Acquired/* /nfs/omv/Big2/Acquired/
rsync -ulrzhv --progress /media/dave/DVD-Moobies/DVD\ Quality/* /nfs/omv/Big2/DVD/


# unmount NAS, or USB, or whatever...
if mounted "$mntpt"; then
    read -p "Unmount NAS?" umount
    if [ "$umount" == "y" ]; then
        sudo umount $mntpt
	echo unmounted $mntpt
    fi
fi

read -p "Shutdown NAS?" diaf
if [ "$diaf" == "y" ]; then
    ssh -t dave@192.168.8.98 'sudo shutdown now'
fi
