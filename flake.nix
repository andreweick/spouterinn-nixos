{
  description = "Spouter Inn — declarative NixOS servers";

  # Same signed binary cache as the upstream installer. Explicit opt-in is
  # needed on the first build; the Pi constructor configures it thereafter.
  nixConfig = {
    extra-substituters = [ "https://nixos-raspberrypi.cachix.org" ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };

  inputs = {
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";
    # Keep board support and the rest of the system on one tested package set.
    nixpkgs.follows = "nixos-raspberrypi/nixpkgs";
  };

  outputs =
    { nixpkgs, nixos-raspberrypi, ... }:
    let
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      nixosConfigurations = {
        dogberry = nixos-raspberrypi.lib.nixosSystem {
          modules = [ ./hosts/dogberry ];
        };
        # Future x86 hosts use nixpkgs.lib.nixosSystem, not the Pi constructor.
      };

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
    };
}
