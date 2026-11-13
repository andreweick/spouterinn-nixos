# spouterinn-nixos

Declarative NixOS configuration for the Spouter Inn fleet. Start small, share
deliberately, and keep every machine's effective configuration easy to follow.

## Fleet

| Host | Hardware | Network | Role |
| --- | --- | --- | --- |
| `dogberry` | Raspberry Pi 5, 8 GB, microSD, PoE HAT | Ethernet DHCP reservation | Packer CLI |

`dogberry` uses `America/New_York` and the `maeick` administrator account.
Its public SSH key is checked into `users/maeick/authorized_key.pub`.
No passwords, private keys, or Proxmox credentials belong in this public repo.

## Layout

```text
flake.nix                    Named hosts, constructors, pinned input wiring
flake.lock                   Exact upstream revisions
hosts/<hostname>/            Identity, hardware inventory, chosen profiles
hardware/                    Reusable board/VM support
profiles/server.nix          Shared server baseline
profiles/roles/              Intent: combinations of capabilities
modules/base/                Nix, networking, SSH policy
modules/services/            Individual capabilities (including CLI tools)
users/<username>/            Account policy and public SSH keys
docs/                        Bootstrap, deployment, and fleet growth
tests/check.sh               Evaluation and first-host policy assertions
```

**Hosts select profiles; profiles compose modules; hardware remains separate.**
Imports are explicit. No directory scans, custom module framework, or hidden
host discovery. Host-specific facts do not leak into shared modules.

Raspberry Pi hosts use `nixos-raspberrypi.lib.nixosSystem`; future x86 hosts use
the standard `nixpkgs.lib.nixosSystem`. Both use the same locked nixpkgs input,
following the board-support project's package set. No Home Manager, deployment
framework, storage formatter, or secret-management backend is required yet.

## Start here

1. [Bootstrap dogberry](docs/bootstrap.md) from its existing installer SD card.
2. [Deploy and maintain](docs/deployment.md).
3. [Add another host](docs/adding-a-host.md).

## Validate

With Nix flakes enabled, Python 3, and OpenSSH tools:

```sh
./tests/check.sh
nix fmt -- --fail-on-change
```

These evaluate the complete ARM system derivation and assert important host
settings on either x86 or ARM. They **do not build or boot the ARM system**.
GitHub Actions runs the same checks; it does not deploy.

## Intentional security choices

- SSH public-key authentication only; no root SSH or installer autologin.
- `maeick` has passwordless sudo. Its SSH key therefore grants effective root.
- Both root and maeick have locked local passwords. There is no console-password
  fallback; read the bootstrap access checks before applying.
- The firewall is enabled; SSH is the only explicitly opened inbound service.
- Packer's unfree-license exception is scoped to Packer, not all packages.
- No unattended upgrades or automatic generation deletion during initial rollout.
- No Proxmox credentials or Packer plugins are configured. Packer on ARM does not
  automatically supply x86 emulation, QEMU/KVM builders, or a Proxmox connection.
- The PoE HAT is inventoried but its model/fan support is not yet configured.

## Upstream references

- Board support: https://github.com/nvmd/nixos-raspberrypi
- Bootloader and installer behavior: upstream README at the revision in `flake.lock`.
- NixOS manual: https://nixos.org/manual/nixos/stable/

The repository is prepared locally; GitHub publication is a separate step.
