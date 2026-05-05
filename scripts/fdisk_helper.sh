fdisk_check_version() {
  for tool in fdisk sfdisk partprobe uuidgen; do
    if ! command -v "${tool}" >/dev/null 2>&1; then
      echo "Error: this script requires ${tool}."
      exit 1
    fi
  done

  local version=$(fdisk --version | grep -oP '\d+\.\d+')
  local major=$(echo "${version}" | cut -d '.' -f 1)
  local minor=$(echo "${version}" | cut -d '.' -f 2)
  if [ "${major}" -lt 2 ] || { [ "${major}" -eq 2 ] && [ "${minor}" -lt 40 ]; }; then
    echo "Error: this script requires fdisk version 2.40 or higher, you have ${version}."
    exit 1
  fi
}

fdisk_resize_last_section() {
  local dev=$1
  # 1. print
  # 2. resize last section
  #    NOTE: command 'e' is added to fdisk 2.40,
  #          we cannot use `d` and `n`, as `Keeping fs signature` must from keyboard input
  # 3. print
  # 4. write & quit
  echo "p
e


p
w
" | sudo fdisk "${dev}"
}

fdisk_randomize_gpt_uuids() {
  local dev=$1
  local disk_uuid
  local boot_part_uuid
  local root_part_uuid

  disk_uuid=$(uuidgen)
  boot_part_uuid=$(uuidgen)
  root_part_uuid=$(uuidgen)

  echo "Setting GPT disk UUID to ${disk_uuid}"
  sudo sfdisk --disk-id "${dev}" "${disk_uuid}"

  echo "Setting boot partition UUID to ${boot_part_uuid}"
  sudo sfdisk --part-uuid "${dev}" 1 "${boot_part_uuid}"

  echo "Setting root partition UUID to ${root_part_uuid}"
  sudo sfdisk --part-uuid "${dev}" 2 "${root_part_uuid}"
}
