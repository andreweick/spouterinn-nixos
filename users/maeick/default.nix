{
  users.mutableUsers = false;
  users.users = {
    root.hashedPassword = "!";
    maeick = {
      isNormalUser = true;
      description = "Administrator";
      extraGroups = [ "wheel" ];
      # SSH-key-only account. Console password login is deliberately disabled.
      hashedPassword = "!";
      openssh.authorizedKeys.keys = [ (builtins.readFile ./authorized_key.pub) ];
    };
  };
  # Key-only administration; anyone with this SSH key effectively has root.
  security.sudo.wheelNeedsPassword = false;
}
