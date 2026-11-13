#!/usr/bin/env bash
set -euo pipefail
# Evaluation only: can run on x86 without emulation or building the ARM kernel.
nix flake check --no-build
nix eval --raw .#nixosConfigurations.dogberry.config.system.build.toplevel.drvPath >/dev/null
nix eval --json .#nixosConfigurations.dogberry.config --apply 'c: {
  hostname = c.networking.hostName;
  system = c.nixpkgs.hostPlatform.system;
  timezone = c.time.timeZone;
  stateVersion = c.system.stateVersion;
  dhcp = c.networking.useDHCP;
  firewall = c.networking.firewall.enable;
  rootLogin = c.services.openssh.settings.PermitRootLogin;
  passwordAuth = c.services.openssh.settings.PasswordAuthentication;
  keyboardAuth = c.services.openssh.settings.KbdInteractiveAuthentication;
  sudoPassword = c.security.sudo.wheelNeedsPassword;
  mutableUsers = c.users.mutableUsers;
  adminPassword = c.users.users.maeick.hashedPassword;
  adminKeys = c.users.users.maeick.openssh.authorizedKeys.keys;
  rootDevice = c.fileSystems."/".device;
  firmwareDevice = c.fileSystems."/boot/firmware".device;
  bootloader = c.boot.loader.raspberry-pi.bootloader;
  packages = map (p: p.pname or p.name) c.environment.systemPackages;
}' | python3 -c '
import json, pathlib, sys
c = json.load(sys.stdin)
expected = {
    "hostname": "dogberry", "system": "aarch64-linux",
    "timezone": "America/New_York", "stateVersion": "26.05",
    "dhcp": True, "firewall": True, "rootLogin": "no",
    "passwordAuth": False, "keyboardAuth": False, "sudoPassword": False,
    "mutableUsers": False, "adminPassword": "!", "bootloader": "kernel",
    "rootDevice": "/dev/disk/by-uuid/44444444-4444-4444-8888-888888888888",
    "firmwareDevice": "/dev/disk/by-uuid/2175-794E",
}
for k, v in expected.items():
    assert c[k] == v, (k, c[k], v)
assert c["adminKeys"] == [pathlib.Path("users/maeick/authorized_key.pub").read_text().strip()]
assert "packer" in c["packages"], c["packages"]
print("dogberry configuration assertions passed")
'
ssh-keygen -lf users/maeick/authorized_key.pub
