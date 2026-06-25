{
    config,
    lib,
    pkgs,
    inputs,
    ...
}:
with lib;
let
    mkServiceUser = name: groups: {
        group = name;
        extraGroups = groups;
        isSystemUser = true;
    };
    generateServiceUsers = attrs: {
        users = mapAttrs (name: groups: mkServiceUser name groups) attrs;
        groups = listToAttrs (flatten (mapAttrsToList (name: groups: [{name = name; value = {};}] ++ map (g: {name = g; value = {};}) groups) attrs));
    };
in
{
    imports = [
        ./provision-secrets.nix
        ./services
    ];

    users = generateServiceUsers {
        deluge = [
            "acquisition"
            "media-service"
        ];
        sonarr = [
            "arr"
            "acquisition"
            "media-service"
        ];
        radarr = [
            "arr"
            "acquisition"
            "media-service"
        ];
        prowlarr = [
            "arr"
            "media-service"
        ];
        seerr = [ "media-service" ];
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
                        "deluge"
                        "arrs/sonarr"
                        "arrs/radarr"
                        "arrs/prowlarr"
                        "seerr"
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
                ];
            };
        };
    };
}
