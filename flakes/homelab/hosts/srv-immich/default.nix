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
            canonicalName = "srv-immich";
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
                order = 100;
            };
            resources.cores = 4;
            resources.memory = 8192;
            storage = {
                disk_size = "128G";
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
                    hash = "$y$j9T$9X1KmUEcPjvdFfZL2bHTg/$N8zODhfP1dlmxrD8qIT3Q5WAeDSvwrzvavmokrEw0K.";
                };
            };
            users = { };
        };
        secrets.system = {
            "immich/encryption-pass" = {};
        };
        volumes = {
            immich-media = {
                enable = true;
                source = {
                    type = "share";
                    name = "data";
                    path = "/data/media/Photos";
                    ensureSource.enable = true;
                };
                destination = "/immich/media";
                strategy.bindMapped = {
                    enable = true;
                    user = "immich";
                    group = "immich";
                    permissions = "0770";
                };
            };
            immich-database = {
                enable = true;
                source = {
                    type = "share";
                    name = "data";
                    path = "/systems/srv-immich/database";
                    ensureSource.enable = true;
                };
                destination = "/immich/database-backups";
                strategy.backup = {
                    enable = true;
                    encryption = {
                        enable = true;
                        passwordFile = config.sops.secrets."immich/encryption-pass".path;
                    };
                    restoration = false;
                    onCalendar = "hourly";
                };
            };
        };
    };

    services.immich = {
        enable = true;
        port = 2283;
        user = "immich";
        group = "immich";
        environment = {
            IMMICH_LOG_LEVEL = "debug";
            TZ = "America/New_York";
            IMMICH_API_METRICS_PORT = "8085";
            IMMICH_MICROSERVICES_METRICS_PORT = "8086";
            IMMICH_TRUSTED_PROXIES = "192.168.64.11";
        };
    };
}
