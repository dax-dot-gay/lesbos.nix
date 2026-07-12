{
    config,
    inputs,
    system,
    lib,
    ...
}: with lib;
{
    options = {
        lesbos.autoUpgrade = {
            activationMode = mkOption {
                description = "Which mode to use for updates from the main branch";
                type = types.enum ["switch" "boot"];
                default = "switch";
                example = "boot";
            };
        };
    };
    config = {
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
                    branches.main.operation = config.lesbos.autoUpgrade.activationMode;
                }
            ];
        };
        nix.gc = {
            automatic = true;
            dates = "Sat *-*-* 01:00:00";
            options = "--delete-older-than 7d";
        };
    };
}
