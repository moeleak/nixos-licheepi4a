{
  buildLinux,
  fetchFromGitHub,
  lib,
  linuxKernel,
  ...
}:

buildLinux rec {
  pname = "linux-th1520";
  version = "7.1.0-rc1";
  modDirVersion = version;

  src = fetchFromGitHub {
    owner = "moeleak";
    repo = "linux";
    rev = "f892dcc9f2c4fb57d4ac2ee59ce2da2136c6439a"; # revyos/7.1.y on 2026-04-30
    sha256 = "sha256-MosBzBYuLwkF7knb2MfT8IuX5z01shO083tDZiBFA7I=";
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
