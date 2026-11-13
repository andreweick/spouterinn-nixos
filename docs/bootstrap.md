# Bootstrap dogberry from the running installer

This is an **in-place conversion**, not a new SD-card image or a repartition.
The reported writable ext4 `/` is already on the microSD. Do not run `mkfs`,
`disko`, or `nixos-install` for this procedure.

## 1. Publish the repository

On the machine holding this repository, authenticate GitHub as the intended
owner. The example assumes `andreweick` owns the new public repo; substitute a
different owner if needed. Do not put a GitHub token in the repository or chat.

```sh
gh auth login
gh repo create andreweick/spouterinn-nixos --public --source=. --remote=origin --push
```

If the repository already exists, configure its remote and push instead of
creating another. No GitHub authentication is required on the Pi to clone a
public repo.

## 2. Check access and storage before changing anything

Keep the KVM connected and the current root installer shell open throughout.
This configuration disables root SSH, installer autologin, and password login.
You must have the private key matching the pinned second GitHub public key:

```text
ED25519 SHA256:RLFKL0qVB1VWB7XC2qLlRYOlz7r9bJQAHabEa2kEhoA
```

On your workstation, inspect available public keys with `ssh-add -l` or
`ssh-keygen -lf /path/to/key.pub`. If none matches, stop and choose a key you
actually possess before proceeding. A GitHub account's key order can change;
the committed key, not the current second line on GitHub, is authoritative.

On the Pi, as root:

```sh
lsblk -o NAME,SIZE,FSTYPE,UUID,MOUNTPOINTS
ls /boot/firmware >/dev/null
findmnt -T /boot/firmware -t vfat
df -h / /boot/firmware
readlink -f /run/current-system
ls -l /nix/var/nix/profiles/system*
```

Verify the FAT mount is `/dev/mmcblk0p1` (UUID `2175-794E`), and root is the
ext4 partition UUID `44444444-4444-4444-8888-888888888888`.
An `autofs` result alone does not establish that the FAT filesystem mounted.
Stop if these do not match. The shared image UUIDs are not safe identifiers
when multiple cloned SD cards are attached to one machine.

Back up the firmware partition to your workstation or another safe location
before changing boot files. A convenient local snapshot to copy off the Pi is:

```sh
tar -C /boot/firmware -czf /root/dogberry-firmware-before.tgz .
```

The FAT partition must have room for new kernels/initrds and retained generations.
If nearly full, stop and inspect; do not manually delete arbitrary boot files.
Record the old generation above and retain the installer image for recovery.

## 3. Clone and build without activating

On the Pi, as root (after the public repository exists):

```sh
export NIX_CONFIG=$'experimental-features = nix-command flakes\naccept-flake-config = true'
nix shell nixpkgs#git -c git clone https://github.com/andreweick/spouterinn-nixos.git /etc/nixos
```

The clone destination must be empty (the reported `/etc/nixos` is empty).
The temporary `nixpkgs#git` shell is just a bootstrap tool; system packages
come from the checked-in lockfile. Accepting flake config opts into the
documented upstream signed Raspberry Pi binary cache; review `flake.nix` first.

Then run the following **from `/etc/nixos`**:

```sh
nix flake metadata
nixos-rebuild build --flake .#dogberry
```

Do not update the lockfile during this first build. Cache misses may cause a
large native build on the Pi; do not assume evaluation checks prove cache coverage.
Building does not switch services or update firmware.

## 4. Activate users/network first, then commit the boot change

Still in `/etc/nixos`, with the root shell and KVM available:

```sh
nixos-rebuild test --flake .#dogberry
```

This activates the new users, SSH policy, and network without making it the
next boot configuration. DHCP may briefly reconnect. From a **new workstation
terminal**, using the matching key, verify:

```sh
ssh maeick@10.200.10.145
sudo -n true
hostname
packer version
```

The address is the one observed during setup; use the DHCP reservation's
current address if it changes. Do not reboot or close the original root
shell until this fresh SSH login and sudo check succeed.

If successful, from the Pi root shell, in `/etc/nixos`:

```sh
nixos-rebuild boot --flake .#dogberry
reboot
```

`boot` writes the next generation and firmware configuration. Do not interrupt
power while it runs. After reboot, repeat the SSH, sudo, hostname, and Packer
checks. Verify `findmnt -T /boot/firmware` after accessing the directory and
`systemctl --failed`.

If SSH fails after `test`, use the still-open root shell to inspect
`journalctl -u sshd`, `ip -br address`, and `getent passwd maeick`. Before
`boot`, a reboot returns to the previous boot configuration. If a boot failure
occurs later, recovery may require bootloader generation selection or mounting
the SD card on another system and restoring the firmware backup. Do not assume
a conventional GRUB menu on this Pi.

## Remaining hardware check

Supply the exact PoE HAT manufacturer/model and confirm the fan/temperature
behavior after the first boot. No HAT overlay or fan driver was guessed.
