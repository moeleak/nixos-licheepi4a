# Generate sdImage for LicheePi 4A
{ config, lib, modulesPath, pkgs, pkgsKernel, ... }: 
let
  rootPartitionUUID = "46545a77-3118-4098-ada3-8882f3ee22d3";
  deviceTreeName = config.hardware.deviceTree.name;
  deviceTreeDir = builtins.dirOf deviceTreeName;
  emptyInitrdFstab = pkgs.writeText "empty-initrd-fstab" "";
  bootScript = pkgs.runCommand "licheepi4a-boot.scr" {
    nativeBuildInputs = [ pkgs.buildPackages.ubootTools ];
  } ''
    cat > boot.cmd <<'EOF'
echo "NixOS: SD is preferred over eMMC"

if test -z "$mmcbootpart"; then
  setenv mmcbootpart 1
fi

if test -z "$mmcdev"; then
  if test -e mmc 1:$mmcbootpart /nixos/Image; then
    setenv mmcdev 1
  else
    setenv mmcdev 0
  fi
fi

echo "NixOS: booting from mmc $mmcdev:$mmcbootpart"

echo "NixOS: using Linux MMC root device"
if test "$mmcdev" = "1"; then
  setenv nixos_root "root=/dev/mmcblk1p2"
else
  setenv nixos_root "root=/dev/mmcblk0p2"
fi

echo "NixOS: kernel root is $nixos_root"
setenv bootargs "init=${config.system.build.toplevel}/init $nixos_root ${toString config.boot.kernelParams}"

if load mmc $mmcdev:$mmcbootpart $kernel_addr_r /nixos/Image; then
  echo "NixOS: loaded kernel"
else
  echo "NixOS: failed to load kernel"
  exit
fi

if load mmc $mmcdev:$mmcbootpart $ramdisk_addr_r /nixos/initrd; then
  setenv initrd_size $filesize
  echo "NixOS: loaded initrd"
else
  echo "NixOS: failed to load initrd"
  exit
fi

if load mmc $mmcdev:$mmcbootpart $fdt_addr_r /nixos/${deviceTreeName}; then
  echo "NixOS: loaded device tree"
else
  echo "NixOS: failed to load device tree"
  exit
fi

booti $kernel_addr_r $ramdisk_addr_r:$initrd_size $fdt_addr_r
EOF

    mkimage -A riscv -T script -C none -n "NixOS LicheePi 4A boot" -d boot.cmd $out
  '';
in {
  imports = [
    ./sd-image.nix
  ];

  boot.initrd.systemd.root = lib.mkForce null;
  boot.initrd.systemd.managerEnvironment.SYSTEMD_SYSROOT_FSTAB = lib.mkForce emptyInitrdFstab;
  boot.initrd.systemd.services.initrd-parse-etc.environment.SYSTEMD_SYSROOT_FSTAB = lib.mkForce emptyInitrdFstab;
  boot.initrd.systemd.storePaths = [ emptyInitrdFstab ];

  # https://github.com/chainsx/fedora-riscv-builder/blob/f46ae18/build.sh#L179-L184
  boot.kernelParams = [
    "console=ttyS0,115200"
    "rootfstype=ext4"
    "rootwait"
    "rw"
    "earlycon"
    "clk_ignore_unused"
    "eth=$ethaddr"       # do not know if this works
    "rootrwoptions=rw,noatime"
    "rootrwreset=yes"
  ];

  boot.loader = {
    grub.enable = false;
    generic-extlinux-compatible.enable = true;
  };

  fileSystems = lib.mkForce {
    "/" = {
      device = "/dev/disk/by-uuid/${rootPartitionUUID}";
      fsType = "ext4";
    };
  };

  sdImage = {
    inherit rootPartitionUUID;

    imageBaseName = "nixos-licheepi4a-sd-image";
    # for local usage, do not need to compress it.
    compressImage = false;
    # install firmware into a separate partition: /boot/firmware
    populateFirmwareCommands = ''
      cp ${pkgsKernel.thead-opensbi}/share/opensbi/lp64/generic/firmware/fw_dynamic.bin firmware/fw_dynamic.bin
      cp ${pkgsKernel.light_aon_fpga}/lib/firmware/light_aon_fpga.bin firmware/light_aon_fpga.bin
      cp ${pkgsKernel.light_c906_audio}/lib/firmware/light_c906_audio.bin firmware/light_c906_audio.bin

      cp ${bootScript} firmware/boot.scr
      mkdir -p firmware/nixos/${deviceTreeDir}
      cp -L ${config.system.build.toplevel}/kernel firmware/nixos/Image
      cp -L ${config.system.build.toplevel}/initrd firmware/nixos/initrd
      cp -L ${config.system.build.toplevel}/dtbs/${deviceTreeName} firmware/nixos/${deviceTreeName}
    '';
    firmwarePartitionName = "BOOT";
    firmwareSize = 200; # MiB

    populateRootCommands = ''
      mkdir -p ./files/boot
    '';
  };
}
