{ config, inputs, ... }:
{
    lesbos.secrets.system = {
        "jellyfin/jellarr-key" = {
            mode = "0444";
        };
        "jellyfin/admin/username" = {
            mode = "0444";
        };
        "jellyfin/admin/password" = {
            mode = "0444";
        };
    };
    lesbos.volumes = {
        media = {
            enable = true;
            source = {
                type = "share";
                name = "data";
                path = "/data/media";
            };
            destination = "/jellyfin/media";
            strategy.bindMapped = {
                enable = true;
                user = "jellyfin";
                group = "jellyfin";
                permissions = "0744";
            };
            required_by = [
                "jellyfin.service"
                "jellarr.service"
                "jellarr-api-key-bootstrap.service"
            ];
        };
        jellyfin-data = {
            enable = true;
            source = {
                type = "share";
                name = "data";
                path = "/systems/srv-jellyfin";
            };
            destination = "/jellyfin/data";
            strategy.bindMapped = {
                enable = true;
                user = "jellyfin";
                group = "jellyfin";
                permissions = "0744,a+D";
            };
            required_by = [
                "jellyfin.service"
                "jellarr.service"
                "jellarr-api-key-bootstrap.service"
            ];
        };
    };
    users = {
        users.jellyfin = {
            isSystemUser = true;
            group = "jellyfin";
        };
        groups.jellyfin = { };
    };
    services.jellarr = {
        enable = false;
        user = "jellyfin";
        group = "jellyfin";
        config = {
            base_url = "http://0.0.0.0:8096";
            system = {
                enableMetrics = true;
                pluginRepositories = [
                    {
                        name = "Jellyfin Official";
                        url = "https://repo.jellyfin.org/releases/plugin/manifest.json";
                        enabled = true;
                    }
                    {
                        name = "Intro Skipper";
                        url = "https://intro-skipper.org/manifest.json";
                        enabled = true;
                    }
                    {
                        name = "Jellyfin Enhanced";
                        url = "https://raw.githubusercontent.com/n00bcodr/jellyfin-plugins/main/10.11/manifest.json";
                        enabled = true;
                    }
                ];
            };
        };
        bootstrap = {
            enable = true;
            apiKeyFile = config.sops.secrets."jellyfin/jellarr-key";
            apiKeyName = "jellarr";
            jellyfinDataDir = "/jellyfin/data";
            jellyfinService = "jellyfin.service";
        };
    };
}
