#!/usr/bin/env bash
set -e

find_default_uboot() {
  for CANDIDATE in \
    ./result-uboot/u-boot-with-spl.bin \
    ./result/u-boot-with-spl.bin \
    ./release/u-boot-with-spl.bin
  do
    if [ -f "${CANDIDATE}" ]; then
      echo "${CANDIDATE}"
      return
    fi
  done
}

DEFAULT_UBOOT=$(find_default_uboot)

if [ -n "${DEFAULT_UBOOT}" ]; then
  echo "Choose U-Boot image (${DEFAULT_UBOOT}):"
else
  echo "Choose U-Boot image:"
fi
read -r UBOOT

UBOOT=${UBOOT:-${DEFAULT_UBOOT}}
if [ -z "${UBOOT}" ] || [ ! -f "${UBOOT}" ]; then
  echo "No such U-Boot image: ${UBOOT}"
  exit 1
fi

FASTBOOT=${FASTBOOT:-fastboot}
SUDO=${SUDO:-sudo}

if ! command -v "${FASTBOOT}" >/dev/null 2>&1; then
  echo "fastboot command not found: ${FASTBOOT}"
  exit 1
fi

echo
echo "Make sure the board is in USB download/fastboot mode."
echo "Current fastboot devices:"
${SUDO} "${FASTBOOT}" devices

echo
echo "Flashing U-Boot into RAM using ${UBOOT}"
${SUDO} "${FASTBOOT}" flash ram "${UBOOT}"

echo
echo "Rebooting into RAM U-Boot"
${SUDO} "${FASTBOOT}" reboot

echo
echo "Wait until the board appears in fastboot again, then press Enter."
read -r _

echo "Current fastboot devices:"
${SUDO} "${FASTBOOT}" devices

echo
echo "Flashing U-Boot partition"
${SUDO} "${FASTBOOT}" flash uboot "${UBOOT}"

echo
echo "Done"
