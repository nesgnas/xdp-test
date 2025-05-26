#!/bin/bash

IFACE="eth0"
BPF_FS="/sys/fs/bpf"
XDP_PROG_PIN="$BPF_FS/xdp_prog"
MAP_PIN="$BPF_FS/blocked_ips"
OBJ_FILE="xdp_drop_ip_kern.o"

echo "========== Reset XDP environment =========="

# 1. Gỡ chương trình XDP hiện tại nếu có
echo "Detaching any existing XDP program from $IFACE..."
sudo ip link set dev $IFACE xdp off || true

# 2. Mount bpffs nếu chưa mount
if ! mount | grep -q "$BPF_FS"; then
  echo "Mounting bpffs on $BPF_FS..."
  sudo mount -t bpf none $BPF_FS
else
  echo "bpffs already mounted on $BPF_FS"
fi

# 3. Xóa các file pin cũ nếu tồn tại
if [ -e "$XDP_PROG_PIN" ]; then
  echo "Removing old pinned XDP program $XDP_PROG_PIN"
  sudo rm -f "$XDP_PROG_PIN"
fi

if [ -e "$MAP_PIN" ]; then
  echo "Removing old pinned map $MAP_PIN"
  sudo rm -f "$MAP_PIN"
fi

# 4. Load và pin XDP program
echo "Loading XDP program from $OBJ_FILE and pinning to $XDP_PROG_PIN..."
sudo bpftool prog load $OBJ_FILE $XDP_PROG_PIN type xdp

# 5. Pin map nếu cần (bạn sửa tên map và lệnh pin cho đúng nếu có)
# Ví dụ:
# echo "Pinning map blocked_ips..."
# sudo bpftool map pin id <map_id> $MAP_PIN

# 6. Attach chương trình XDP vào interface
echo "Attaching XDP program to $IFACE..."
sudo ip link set dev $IFACE xdp pinned $XDP_PROG_PIN

# 7. Kiểm tra trạng thái interface
echo "Interface $IFACE details:"
ip -details link show dev $IFACE

echo "========== Done =========="

