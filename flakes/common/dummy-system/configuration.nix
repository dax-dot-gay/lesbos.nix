{
    pkgs,
    inputs,
    ...
}:
{
    imports = [
        ./hardware-configuration.nix
    ];

    system.stateVersion = "26.05";
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

    lesbos.proxmox = {
        enable = true;
        metadata = {
            id = 502;
            name = "test-dummy.lesbos";
            tags = ["lesbos.nix" "testing"];
        };
        storage = {
            volume = "core-encrypted";
            disk_size = 20480;
            boot_size = "512M";
            extra_disks = [
                {
                    device = "virtio1";
                    name = "test-disk";
                }
            ];
        };
        resources = {
            cores = 4;
        };
        network_interfaces = {
            extra_interfaces = [
                {
                    bridge = "vmbr3";
                }
            ];
        };
        agent = true;
        watchdog.enable = true;
    };
}
