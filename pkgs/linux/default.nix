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
    rev = "bf46daffc5565a8502f604fc91105dffcbe99637"; # revyos/7.3.y on 2026-11-20
    sha256 = "sha256-KKO96zvOW131aYQzR//veNPW57Puq64GkKY7WnyD3sQ=";
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
