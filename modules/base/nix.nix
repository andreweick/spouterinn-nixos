{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # Wheel users already have root via sudo; do not grant extra Nix trust.
    trusted-users = [ "root" ];
  };
  # No unattended input updates or generation deletion during initial rollout.
}
