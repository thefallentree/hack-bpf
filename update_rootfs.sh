#!/bin/bash

# Check we are root.
if [[ "$(id -u)" != 0 ]]; then
   echo "$0 must run as root"
   exit 1
fi

set -x

set -euo pipefail
trap 'exit 2' ERR

ARCH="x86_64"
BASE_IMG="rootfs/rootfs-base.tar.zst"
IMG="rootfs.img"
VMLINUZ=linux/"$(make -C linux -s image_name)"
VMLINUX=linux/vmlinux

MAX_CPU=${MAX_CPU:-$(nproc)}
GDB=${GDB:-0}


echo "Preparing rootfs"



set_nocow() {
	touch "$@"
	chattr +C "$@" >/dev/null 2>&1 || true
}

create_rootfs_img() {
	local path="$1"
	set_nocow "$path"
	truncate -s 2G "$path"
	mkfs.ext4 -q "$path"
}

tar_in() {
	local dst_path="$1"
	# guestfish --remote does not forward file descriptors, which prevents
	# us from using `tar-in -` or bash process substitution. We don't want
	# to copy all the data into a temporary file, so use a FIFO.
	tmp=$(mktemp -d)
	mkfifo "$tmp/fifo"
	cat >"$tmp/fifo" &
	local cat_pid=$!
	guestfish --remote tar-in "$tmp/fifo" "$dst_path"
	wait "$cat_pid"
	rm -r "$tmp"
	tmp=
}

eval "$(guestfish --listen)"

if [[ ! -f "$IMG" ]]; then
	create_rootfs_img $IMG

	guestfish --remote \
		add "$IMG" label:img : \
		launch : \
		mount /dev/disk/guestfs/img /

	cat $BASE_IMG | zstd -d | tar_in /
else
 	guestfish --remote \
		add "$IMG" label:img : \
		launch : \
		mount /dev/disk/guestfs/img /
fi

guestfish --remote \
	upload "$VMLINUX" "/boot/vmlinux" : \
	chmod 644 "/boot/vmlinux"

guestfish --remote \
	upload "./linux/tools/testing/selftests/bpf/test_progs" "/root/test_progs" : \
	chmod 755 "/root/test_progs"

guestfish --remote \
	upload "/lib/x86_64-linux-gnu/libc.so" "/root/libc.so" : \
	chmod 755 "/root/libc.so"

guestfish --remote \
	upload "/lib/x86_64-linux-gnu/libc.so.6" "/root/libc.so.6" : \
	chmod 755 "/root/libc.so.6"

guestfish --remote exit


