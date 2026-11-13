{ pkgs, ... }:
{
  imports = [ ../modules/base ];
  environment.systemPackages = with pkgs; [
    git
    curl
    vim
  ];
  zramSwap.enable = true;
}
