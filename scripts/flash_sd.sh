#!/usr/bin/env bash
set -e

CURRENT_DIR=$(dirname "$(readlink -f "$0")")
source "${CURRENT_DIR}/fdisk_helper.sh"
source "${CURRENT_DIR}/img_helper.sh"

fdisk_check_version

select_img

echo
lsblk

echo "Choose flash target (e.g. sdb or /dev/sdb):"
read -r TARGET

if [ "${TARGET#/dev/}" != "${TARGET}" ]; then
  TARGET_DEV="${TARGET}"
  TARGET_NAME=$(basename "${TARGET}")
else
  TARGET_DEV="/dev/${TARGET}"
  TARGET_NAME="${TARGET}"
fi

if ! [ -b "${TARGET_DEV}" ]; then
  echo "No such device: ${TARGET_DEV}"
  exit 1
fi

if [ "$(lsblk -dnro TYPE "${TARGET_DEV}")" != "disk" ]; then
  echo "Target must be a whole disk: ${TARGET_DEV}"
  exit 1
fi

echo "This will erase ${TARGET_DEV}. Type '${TARGET_NAME}' to continue:"
read -r CONFIRM
if [ "${CONFIRM}" != "${TARGET_NAME}" ]; then
  echo "Cancelled"
  exit 1
fi

echo
echo "Unmounting ${TARGET_DEV} partitions"
while read -r PART; do
  echo "Unmounting ${PART}"
  sudo umount "${PART}" || true
done < <(lsblk -lnpo NAME,TYPE "${TARGET_DEV}" | awk '$2 == "part" { print $1 }')

echo
echo "Flashing ${TARGET_DEV} using ${IMAGE}"
sudo dd if="${IMAGE}" of="${TARGET_DEV}" bs=4M status=progress conv=fsync
sudo partprobe "${TARGET_DEV}" || true
sleep 1

echo
echo "Fixing disk section size"
fdisk_resize_last_section "${TARGET_DEV}"

echo
echo "Randomizing GPT UUIDs"
fdisk_randomize_gpt_uuids "${TARGET_DEV}"
sudo partprobe "${TARGET_DEV}" || true
sleep 1

echo
echo "Verifying partition table"
sudo sfdisk --verify "${TARGET_DEV}"

echo
echo "Fsck"
ROOT_PART=$(lsblk -lnpo NAME,TYPE "${TARGET_DEV}" | awk '$2 == "part" { parts[++i] = $1 } END { print parts[2] }')
if [ -z "${ROOT_PART}" ]; then
  echo "Could not find root partition on ${TARGET_DEV}"
  exit 1
fi
sudo fsck "${ROOT_PART}"

echo
echo "Resizing fs"
sudo resize2fs "${ROOT_PART}"

echo
sync
echo "Done"
