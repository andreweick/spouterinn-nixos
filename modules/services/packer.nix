{ lib, pkgs, ... }:
{
  # Packer is a CLI, not a daemon. Limit the unfree exception to Packer.
  nixpkgs.config.allowUnfreePredicate = pkg: lib.getName pkg == "packer";
  environment.systemPackages = [ pkgs.packer ];
}
