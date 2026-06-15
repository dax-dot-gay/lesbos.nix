{
    config,
    pkgs,
    lib,
    inputs,
    ...
}:
{
    imports = [
        ./hardware-configuration.nix
    ];

    system.stateVersion = "26.05";
    networking.hostName = "lesbos-common-dummy";
    time.timeZone = "America/New_York";
    users.users.dummy = {
        extraGroups = [ "wheel" ];
        isNormalUser = true;
        password = "dummy";
    };
    services.openssh = {
        enable = true;
        openFirewall = true;
    };
    environment.systemPackages = [
        pkgs.neovim
        pkgs.ghostty.terminfo
        pkgs.git
    ];
    nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
    nix.registry.nixpkgs.flake = inputs.nixpkgs;
    nixpkgs.config.allowUnfree = true;
    nix.settings.experimental-features = [
        "nix-command"
        "flakes"
    ];
}
