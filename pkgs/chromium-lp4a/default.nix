{
  buildPackages,
  callPackage,
  lib,
  path,
}:

let
  nixpkgsWithLp4aChromium = buildPackages.applyPatches {
    name = "nixpkgs-chromium-lp4a";
    src = path;
    patches = [
      ./patches/0001-chromium-enable-riscv64-v4l2-codec.patch
    ];
  };
in
(callPackage "${nixpkgsWithLp4aChromium}/pkgs/applications/networking/browsers/chromium" {
  commandLineArgs = lib.concatStringsSep " " [
    "--ignore-gpu-blocklist"
    "--enable-native-gpu-memory-buffers"
    "--enable-features=V4L2FlatStatefulVideoDecoder,V4L2FlatStatelessVideoDecoder"
  ];
}).overrideAttrs
  (old: {
    pname = "chromium-lp4a";
    meta = old.meta // {
      description = "Chromium with LP4A/RISC-V V4L2 hardware video decode enabled";
    };
  })
