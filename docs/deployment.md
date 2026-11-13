# Deployment and maintenance

Run these from the repository root on the target machine. Public GitHub holds
the configuration, not credentials and not an automatic deployment agent.

## Routine changes

Edit locally, validate, commit, review the diff, and push. Then on dogberry:

```sh
git pull --ff-only
sudo nixos-rebuild build --flake .#dogberry
sudo nixos-rebuild test --flake .#dogberry
```

Keep an existing session open and test fresh SSH login plus `sudo -n true`.
For ordinary non-kernel changes:

```sh
sudo nixos-rebuild switch --flake .#dogberry
```

For kernel/firmware changes, after the access check:

```sh
sudo nixos-rebuild boot --flake .#dogberry
sudo reboot
```

If the checkout is root-owned under `/etc/nixos`, use `sudo git pull --ff-only`
instead. Git does not need a GitHub token for public reads.

## Deliberate dependency updates

On a development checkout, not as a side effect of deployment:

```sh
nix flake update nixos-raspberrypi
./tests/check.sh
nix fmt -- --fail-on-change
git diff -- flake.lock
```

Review, commit, and push the new lockfile before deploying. This updates board
support and its followed nixpkgs together. The first provisioning release is
recorded as `system.stateVersion = "26.05"`; this is not an update channel and
should not be bumped just because packages or NixOS have been upgraded.

## Rollback and recovery

For an activation regression with working access:

```sh
sudo nixos-rebuild switch --rollback
```

Review generations with `sudo nix-env --list-generations -p
/nix/var/nix/profiles/system`. A rollback can change user and SSH policy too.
Keep copies of firmware backups and a recovery image off the SD card; do not
count on SSH to repair a boot failure. See the bootstrap guide for limitations.

No scheduled garbage collection is enabled. Periodically inspect `/nix/store`
and filesystem space. Keep known-good generations while bringing up the host;
do not aggressively prune them on a new hardware/kernel combination.

## Keys, passwords, and secrets

To rotate access, add the replacement public key, deploy, verify a fresh login,
and only then remove the old key in a second deployment. Public key fingerprints
in the bootstrap documentation must be updated when changing the pinned key.

Local root and admin passwords are declaratively locked (`users.mutableUsers =
false`). Running `passwd` is not a durable configuration change. If a console
password fallback is desired, design a runtime secret-file mechanism before
changing this policy. Neither plaintext passwords nor private password hashes
belong in this public repo.

Future Proxmox API credentials should be scoped, runtime-only secrets. Do not
embed them in Nix expressions: those can end up in the world-readable Nix store.
Choose a secret manager such as sops-nix/agenix when there is an actual service
requiring it, not as unused scaffolding.

## Packer scope

The role installs only the CLI. Keep image templates in the image-building repo.
Declare plugin requirements there and use `packer init`. Supply credentials
outside Git. A Proxmox API builder can orchestrate remote image builds, whereas
local x86 emulation on this ARM Pi would require a separate QEMU design.
