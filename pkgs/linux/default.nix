{
  buildLinux,
  fetchFromGitHub,
  lib,
  linuxKernel,
  ...
}:

buildLinux rec {
  pname = "linux-th1520";
  version = "7.3.5";
  modDirVersion = version;

  src = fetchFromGitHub {
    owner = "moeleak";
    repo = "linux";
    rev = "c43e3bfd3edf96344672b1a9a3642771a0062676"; # revyos/7.3.y on 2026-11-20
    sha256 = "sha256-oTra2JXYm3SbpffB/CMjEVSn5HX2+544tcKV6iAbLj4=";
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
    branch = "revyos/7.3.y";
    platforms = [ "riscv64-linux" ];
  };
}
