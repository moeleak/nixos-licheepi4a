{
  buildLinux,
  fetchFromGitHub,
  lib,
  linuxKernel,
  ...
}:

buildLinux rec {
  pname = "linux-th1520";
  version = "7.1.0-rc2";
  modDirVersion = version;

  src = fetchFromGitHub {
    owner = "moeleak";
    repo = "linux";
    rev = "57e198b2c91a70f2683845fa44d39c1af3c88856"; # revyos/7.1.y on 2026-05-06
    sha256 = "sha256-NIs4QgZXV6USYHtjT2LN8YVaMxm1hz7SA4NFF8ONrMg=";
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
