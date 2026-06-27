{
    config,
    lib,
    pkgs,
    inputs,
    ...
}:
{
    imports = [
        ./provision-secrets.nix
        ./syncthing.nix
    ];
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
            };
        };
        volumes = {
            sync = {
                enable = true;
                source = {
                    type = "share";
                    name = "data";
                    path = "/data/home/sync";
                };
                destination = "/syncthing/shared-folders";
                strategy.bindMapped = {
                    enable = true;
                    user = "syncthing";
                    group = "syncthing";
                    permissions = "0770";
                };
                required_by = ["syncthing.service"];
            };
        };
    };

    users.users.syncthing = {
        group = "syncthing";
        isSystemUser = true;
    };
    users.groups.syncthing = { };

    environment.systemPackages = with pkgs; [
        borgbackup
        rclone
        yazi
    ];
}
