{
    config,
    lib,
    pkgs,
    inputs,
    ...
}:
with lib;
{
    imports = [
        ./provision-secrets.nix
        ./services
    ];

    users = {
        users = {
            deluge = {
                group = mkDefault "deluge";
                extraGroups = ["media-service" "acquisition"];
                isSystemUser = true;
            };
            sonarr = {
                group = mkDefault "sonarr";
                extraGroups = ["media-service" "acquisition" "arr"];
                isSystemUser = true;
            };
            radarr = {
                group = mkDefault "radarr";
                extraGroups = ["media-service" "acquisition" "arr"];
                isSystemUser = true;
            };
            prowlarr = {
                group = mkDefault "prowlarr";
                extraGroups = ["media-service" "arr"];
                isSystemUser = true;
            };
            seerr = {
                group = mkDefault "seerr";
                extraGroups = ["media-service"];
                uid = 996;
            };
            common = {
                group = mkDefault "media-service";
                uid = 1000;
                isSystemUser = true;
            };
        };
        groups = {
            deluge = {};
            sonarr = {};
            radarr = {};
            prowlarr = {};
            seerr = {};
            media-service = {gid = 996;};
            acquisition = {};
            arr = {};
        };
    };

    lesbos = {
        info = {
            canonicalName = "srv-media-support";
            flake = "homelab";
            stateVersion = "26.05";
            runningVersion = "26.05";
        };
        proxmox = {
            enable = true;
            network.primary.bridge = "vmbr3";
            storage = {
                disk_size = "256G";
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
            resources.cores = 4;
            resources.memory = 8192;
            start.order = 100;
        };
        base.users = {
            root = {
                enable = true;
                ssh.enable = true;
                password = {
                    enable = true;
                    hash = "$y$j9T$PzX4FuuAnML7rQw3yvC3/.$I4uFhMWOOWIS244UjKIjHBVKnaMo3L0BwB4/MzXL6p4";
                };
            };
            users = { };
        };
        volumes = {
            media = {
                enable = true;
                source = {
                    type = "share";
                    name = "data";
                    path = "/data/media";
                };
                destination = "/media-support/media";
                strategy.bindMapped = {
                    enable = true;
                    user = "root";
                    group = "media-service";
                    permissions = "0770";
                };
                required_by = [
                    "deluged.service"
                    "sonarr.service"
                    "radarr.service"
                    "prowlarr.service"
                    "bazarr.service"
                    "shelfarr.service"
                    "lidarr.service"
                ];
            };
            downloads = {
                enable = true;
                source = {
                    type = "share";
                    name = "data";
                    path = "/systems/srv-media-support/downloads";
                    ensureSource = {
                        enable = true;
                    };
                    subdirectories = [
                        "torrents"
                        "downloads"
                    ];
                };
                destination = "/media-support/downloads";
                strategy.bindMapped = {
                    enable = true;
                    user = "root";
                    group = "acquisition";
                    permissions = "0770";
                };
                required_by = [
                    "deluged.service"
                    "sonarr.service"
                    "radarr.service"
                    "prowlarr.service"
                    "bazarr.service"
                    "lidarr.service"
                ];
            };
            service-data = {
                enable = true;
                source = {
                    type = "share";
                    name = "data";
                    path = "/systems/srv-media-support/services";
                    ensureSource = {
                        enable = true;
                    };
                    subdirectories = [
                        "arrs/sonarr"
                        "arrs/radarr"
                        "arrs/prowlarr"
                        "arrs/bazarr"
                        "arrs/lidarr"
                        "seerr"
                        "shelfarr/data"
                        "shelfarr/downloads"
                        "downloaders/deluge"
                        "downloaders/slskd"
                        "downloaders/gluetun"
                    ];
                };
                destination = "/media-support/services";
                strategy.bindMapped = {
                    enable = true;
                    user = "root";
                    group = "media-service";
                    permissions = "0770";
                };
                required_by = [
                    "deluged.service"
                    "sonarr.service"
                    "radarr.service"
                    "prowlarr.service"
                    "seerr.service"
                    "lidarr.service"
                    "bazarr.service"
                    "shelfarr.service"
                ];
            };
        };
    };
}
