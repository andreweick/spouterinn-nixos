# Adding a host

1. Choose a hostname and collect the real hardware/storage facts.
2. Create `hosts/<hostname>/default.nix` and `hardware-configuration.nix`.
   Generate hardware facts on that machine (`nixos-generate-config --show-hardware-config`)
   and review them; never copy dogberry's UUIDs.
3. Import the shared server profile, users, and only the roles needed.
4. Register the host explicitly in `flake.nix`.
5. Evaluate its toplevel derivation, build on an appropriate machine, and use
   the same staged access checks as dogberry.

Host module shape:

```nix
{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/server.nix
    ../../users/maeick
    # Select role profiles here.
  ];
  networking.hostName = "example";
  time.timeZone = "America/New_York";
  system.stateVersion = "26.05"; # Actual initial provisioning release.
}
```

For another Raspberry Pi 5, also import
`../../hardware/raspberry-pi-5.nix` and register it with:

```nix
example = nixos-raspberrypi.lib.nixosSystem {
  modules = [ ./hosts/example ];
};
```

For an x86 Proxmox VM, use the normal constructor (no Pi overlays):

```nix
example = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [ ./hosts/example ];
};
```

For a Proxmox VM, add a reusable `hardware/proxmox-vm.nix` only once its
boot mode, storage controller, and disk layout are known. Likely shared
capabilities include `services.qemuGuest.enable = true`; EFI and BIOS need
different bootloader choices, so do not guess. For a public VPS, make the
provider's storage/network details explicit at the host layer.

`./tests/check.sh` currently contains dogberry-specific assertions. Extend the
checks as the fleet grows; `nix flake check --no-build` also evaluates every
registered NixOS host.

## Where should a setting go?

- UUID, hostname, initial state version, timezone: host.
- Board/virtual platform support: hardware.
- Shared SSH/Nix/network policy: base modules.
- One service's package and daemon settings: service module.
- Several services that fulfill one purpose: role profile.
- A reusable administrator identity/public key: user module.

Avoid inventing an option hierarchy until needed. Plain modules and explicit
imports are sufficient for a small heterogeneous fleet. If a service needs
parameters or opt-in configuration, introduce a typed custom option in that
service module when the second use case calls for it.
