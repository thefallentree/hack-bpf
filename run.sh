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

echo "Starting VM with $(nproc) CPUs..."

APPEND=${APPEND:-}

case "$ARCH" in
x86_64)
	qemu="qemu-system-x86_64"
	console="ttyS0,115200"
	smp=$(nproc)
	kvm_accel="-cpu kvm64 -enable-kvm"
	tcg_accel="-cpu qemu64 -machine accel=tcg"
	;;
*)
	echo "Unsupported architecture"
	exit 1
	;;
esac

if kvm-ok ; then
  accel=$kvm_accel
else
  accel=$tcg_accel
fi

debug=""
if [[ "$GDB" == "1" ]]; then
	debug="-s -S"
fi

console="ttyS0,115200"
"$qemu" -nodefaults --no-reboot -nographic \
  -serial mon:stdio \
  ${accel} -smp 1 -m 4G \
  ${debug} \
  -drive file="$IMG",format=raw,index=1,media=disk,if=virtio \
  -kernel "$VMLINUZ" -append "root=/dev/vda rw nokaslr console=$console"

