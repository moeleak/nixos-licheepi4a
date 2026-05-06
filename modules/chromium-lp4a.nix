{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    chromium-lp4a
    v4l-utils
    libva-utils

    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-libav
  ];

  services.udev.extraRules = ''
    SUBSYSTEM=="video4linux", GROUP="video", MODE="0660"
    SUBSYSTEM=="media", GROUP="video", MODE="0660"
    SUBSYSTEM=="drm", KERNEL=="renderD*", GROUP="render", MODE="0660"

    KERNEL=="hantrodec", GROUP="video", MODE="0660"
    KERNEL=="vc8000", GROUP="video", MODE="0660"
    KERNEL=="vidmem", GROUP="video", MODE="0660"
    KERNEL=="memalloc", GROUP="video", MODE="0660"
  '';
}
