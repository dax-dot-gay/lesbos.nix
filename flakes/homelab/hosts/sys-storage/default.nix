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
        ./backup.nix
        ./sftpgo.nix
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
            resources.memory = 8192;
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
                required_by = [ "syncthing.service" ];
            };
            syncthing-data = {
                enable = true;
                source = {
                    type = "share";
                    name = "data";
                    path = "/systems/sys-storage/syncthing";
                    ensureSource.enable = true;
                };
                destination = "/syncthing/service";
                strategy.bindMapped = {
                    enable = true;
                    user = "syncthing";
                    group = "syncthing";
                    permissions = "0770";
                };
                required_by = [ "syncthing.service" ];
            };
            backup-service-data = {
                enable = true;
                source = {
                    type = "share";
                    name = "data";
                    path = "/systems/sys-storage/backups";
                    ensureSource.enable = true;
                    subdirectories = [
                        "app"
                        "ssh/host"
                        "ssh/user"
                    ];
                };
                destination = "/borgbackup/app";
                strategy.bindMapped = {
                    enable = true;
                    user = "borgwarehouse";
                    group = "borgwarehouse";
                    permissions = "0700";
                };
                required_by = ["borgwarehouse.service"];
            };
            backup-repositories = {
                enable = true;
                source = {
                    type = "share";
                    name = "data";
                    path = "/data/backups/borg";
                    ensureSource.enable = true;
                };
                destination = "/borgbackup/backups";
                strategy.bindMapped = {
                    enable = true;
                    user = "borgwarehouse";
                    group = "borgwarehouse";
                    permissions = "0700";
                };
                required_by = ["borgwarehouse.service"];
            };
        };
    };

    users.users.syncthing = {
        group = "syncthing";
        isSystemUser = true;
    };
    users.users.borgwarehouse = {
        group = "borgwarehouse";
        isSystemUser = true;
        uid = 348;
    };
    users.groups.syncthing = { };
    users.groups.borgwarehouse = {
        gid = 348;
    };

    environment.systemPackages = with pkgs; [
        borgbackup
        rclone
        yazi
    ];
}
