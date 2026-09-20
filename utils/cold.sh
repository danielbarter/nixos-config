# This file is intended to be sourced by an interactive shell.
# shellcheck shell=bash

# Format a block device with GPT, create 1 partition labeled "cold", and make ext4
# Usage: format_cold /dev/sdX   (or /dev/nvme0n1)
format_cold() {
  set -euo pipefail

  if [[ $# -ne 1 ]]; then
    echo "Usage: format_cold /dev/<disk>" >&2
    return 2
  fi

  local disk="$1"

  if [[ ! -b "$disk" ]]; then
    echo "Error: '$disk' is not a block device." >&2
    return 2
  fi

  # Refuse obvious partition paths (expects whole-disk like /dev/sdb, /dev/nvme0n1)
  if [[ "$disk" =~ [0-9]$ ]] && [[ ! "$disk" =~ nvme[0-9]n[0-9]$ ]]; then
    echo "Error: '$disk' looks like a partition; pass the whole disk (e.g. /dev/sdb)." >&2
    return 2
  fi

  echo "About to DESTROY all data on: $disk" >&2
  echo "Current layout:" >&2
  lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT "$disk" >&2 || true

  # If anything is mounted from this disk, unmount it.
  local mps
  mps="$(lsblk -nr -o MOUNTPOINT "$disk" | awk 'NF{print}')"
  if [[ -n "${mps}" ]]; then
    echo "Unmounting mounted filesystems on $disk..." >&2
    while read -r mp; do
      sudo umount "$mp"
    done <<< "${mps}"
  fi

  # Zap signatures (best-effort) to avoid old superblocks confusing tools.
  sudo wipefs -a "$disk"

  # Create GPT and one primary partition spanning the disk.
  sudo parted -s "$disk" mklabel gpt
  sudo parted -s "$disk" mkpart primary ext4 1MiB 100%

  # Ensure kernel sees new partition table.
  sudo partprobe "$disk"
  sudo udevadm settle

  # Determine created partition path.
  local part
  if [[ "$disk" =~ nvme[0-9]n[0-9]$ ]]; then
    part="${disk}p1"
  else
    part="${disk}1"
  fi

  if [[ ! -b "$part" ]]; then
    echo "Error: partition device '$part' not found." >&2
    return 1
  fi

  # Make ext4 with filesystem label "cold"
  sudo mkfs.ext4 -F -L cold "$part"

  echo "Done." >&2
  echo "Disk:  $disk" >&2
  echo "Part:  $part" >&2
  echo "Label: cold" >&2
}
