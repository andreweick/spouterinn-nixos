{ lib, ... }:
{
  networking.useDHCP = lib.mkDefault true;
  networking.networkmanager.enable = lib.mkDefault false;
  networking.wireless.enable = lib.mkDefault false;
  networking.firewall.enable = true;
}
