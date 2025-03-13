{ ... }:
{
  hardware = {
    raspberry-pi."4".poe-plus-hat.enable = true;
    deviceTree = {
      enable = true;
      filter = "bcm2711-rpi-4*.dtb";
      overlays = [{
        name = "rpi-poe";
        dtsFile = ./rpi-poe.dts;
      }];
    };
  };
}
