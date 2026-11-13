{ nixos-raspberrypi, ... }:
{
  imports = [ nixos-raspberrypi.nixosModules.raspberry-pi-5.base ];

  # Match the installer's generational bootloader, not legacy kernelboot.
  boot.loader.raspberry-pi.bootloader = "kernel";
  boot.loader.raspberry-pi.configurationLimit = 4;

  # Board/RAM-specific tuning belongs here, not in generic server modules.
  # No PoE overlay assumed: HAT make/model is not yet known.
}
