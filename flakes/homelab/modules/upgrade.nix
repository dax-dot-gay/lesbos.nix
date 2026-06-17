{ config, ... }:
{
    nixos-utilities.services.autoUpgrade = {
        enable = true;
        comin = {
            repositorySubdir = "flakes/homelab";
        };
        identification = {
            hostname = config.lesbos.proxmox.metadata.name;
        };
        reboot = {
            enable = true;
            mode = "auto";
            rebootWindow = {
                lower = "01:00";
                upper = "05:00";
            };
        };
        remotes = [
            {
                name = "origin";
                url = "https://github.com/dax-dot-gay/lesbos.nix.git";
            }
        ];
    };
}
