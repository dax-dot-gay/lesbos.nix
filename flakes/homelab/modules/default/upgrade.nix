{ config, inputs, system, lib, ... }:
{
    nixos-utilities.services.autoUpgrade = {
        enable = true;
        comin = {
            repositorySubdir = "flakes/homelab";
            package = lib.mkForce inputs.comin.packages.${system}.default;
        };
        identification = {
            hostname = config.lesbos.info.canonicalName;
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
