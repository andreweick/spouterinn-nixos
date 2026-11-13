{
  imports = [
    ./hardware-configuration.nix
    ../../hardware/raspberry-pi-5.nix
    ../../profiles/server.nix
    ../../profiles/roles/packer-builder.nix
    ../../users/maeick
  ];

  networking.hostName = "dogberry";
  time.timeZone = "America/New_York";

  # Record the release at first provisioning; do not bump on routine upgrades.
  system.stateVersion = "26.05";
}
