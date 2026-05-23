{
  buildLinux,
  fetchFromGitHub,
  lib,
  linuxKernel,
  ...
}:

buildLinux rec {
  pname = "linux-th1520";
  version = "7.1.0-rc4";
  modDirVersion = version;

  src = fetchFromGitHub {
    owner = "moeleak";
    repo = "linux";
    rev = "c09b71dc141b165fe509ca4fadbbcd3b862ec29f"; # revyos/7.1.y on 2026-05-23
    sha256 = "sha256-Do0Z5kLyynfw/piTuouF7m3SuHxNA0LtJe8tsrUcHpY=";
  };

  defconfig = "debian_defconfig";

  kernelPatches = with linuxKernel.kernelPatches; [
    bridge_stp_helper
    request_key_helper
  ];

  structuredExtraConfig = with lib.kernel; {
    DRM_POWERVR = module;
    PSTORE = yes;
  };

  extraMeta = {
    branch = "revyos/7.1.y";
    platforms = [ "riscv64-linux" ];
  };
}
