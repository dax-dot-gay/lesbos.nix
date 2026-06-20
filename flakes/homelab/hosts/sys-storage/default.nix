{
    config,
    lib,
    pkgs,
    inputs,
    ...
}:
{
    imports = [ ./provision-secrets.nix ];
    lesbos = {
        info = {
            canonicalName = "sys-storage";
            flake = "homelab";
            stateVersion = "26.05";
            runningVersion = "26.05";
        };
        proxmox = {
            enable = true;
            network.primary.bridge = "vmbr3";
            watchdog.enable = true;
            start = {
                on_boot = true;
                on_deploy = true;
                order = 2;
            };
            resources.cores = 4;
            resources.memory = 2048;
            storage = {
                disk_size = "64G";
                virtiofs = [
                    {
                        name = "data";
                        mount = true;
                        id = "DATA";
                        expose_acl = true;
                        expose_xattr = true;
                    }
                ];
            };
        };
        base.users = {
            root = {
                enable = true;
                ssh.enable = true;
                password = {
                    enable = true;
                    hash = "$y$j9T$lY/.W4pcEZkCzSXBVeLbR0$RdjiQ2BGul1IF.UsAZRIVLXgMNhPV3aTxhRel5TH7Q1";
                };
            };
            users = {
                "nas" = {
                    enable = true;
                    ssh.enable = true;
                    password = {
                        enable = true;
                        hash = "$y$j9T$qj3cTXorHG10xYno5IgbV/$XP4/BLaoI0.Jq0jRD7KsDkLehCOpL3anTrbmJ9fseC/";
                    };
                    sudo = false;
                };
            };
        };
    };
}
