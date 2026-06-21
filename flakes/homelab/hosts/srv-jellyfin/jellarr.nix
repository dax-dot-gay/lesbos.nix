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
    sops.templates."jellarr.env" = {
        owner = "jellyfin";
        group = "jellyfin";
        mode = "0440";
        content = ''
            JELLARR_API_KEY=${config.sops.placeholder."jellyfin/jellarr-key"}
        '';
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
                permissions = "0740";
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
                ensureSource.enable = true;
                subdirectories = [
                    "data"
                    "cache"
                    "config"
                    "logs"
                ];
            };
            destination = "/jellyfin/data";
            strategy.sync = {
                enable = true;
                user = "jellyfin";
                group = "jellyfin";
                mode = "0740";
                restoration = true;
                timerConfig = {
                    OnActiveSec = "1h";
                };
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
        enable = true;
        user = "jellyfin";
        group = "jellyfin";
        environmentFile = config.sops.templates."jellarr.env".path;
        config = {
            version = 1;
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
                trickplayOptions = {
                    enableHwAcceleration = true;
                    enableHwEncoding = true;
                };
            };
            encoding = {
                enableHardwareEncoding = true;
                hardwareAccelerationType = "nvenc";
                hardwareDecodingCodecs = [
                    "h264"
                    "hevc"
                    "mpeg2video"
                    "vp9"
                    "vc1"
                ];
                enableDecodingColorDepth10Hevc = true;
                enableDecodingColorDepth10Vp9 = true;
                allowHevcEncoding = true;
            };
            library = {
                virtualFolders = [
                    {
                        name = "Movies";
                        collectionType = "movies";
                        libraryOptions = {
                            pathInfos = [
                                {
                                    path = "/jellyfin/media/Movies";
                                }
                            ];
                        };
                    }
                    {
                        name = "Shows";
                        collectionType = "tvshows";
                        libraryOptions = {
                            pathInfos = [
                                {
                                    path = "/jellyfin/media/Shows";
                                }
                            ];
                        };
                    }
                    {
                        name = "Music";
                        collectionType = "music";
                        libraryOptions = {
                            pathInfos = [
                                {
                                    path = "/jellyfin/media/Songs";
                                }
                            ];
                        };
                    }
                ];
            };
            branding = {
                loginDisclaimer = "Powered by: Lesbianism & NixOS";
                customCss = ''@import url("https://cdn.jsdelivr.net/gh/lscambo13/ElegantFin@main/Theme/ElegantFin-jellyfin-theme-build-latest-minified.css");'';
            };
            users = [
                {
                    name = "dax";
                    passwordFile = config.sops.secrets."jellyfin/admin/password".path;
                    policy = {
                        isAdministrator = true;
                        loginAttemptsBeforeLockout = 3;
                    };
                }
            ];
            startup.completeStartupWizard = true;
        };
        bootstrap = {
            enable = true;
            apiKeyFile = config.sops.secrets."jellyfin/jellarr-key".path;
            apiKeyName = "jellarr";
            jellyfinDataDir = "/jellyfin/data/data";
            jellyfinService = "jellyfin.service";
        };
    };
    services.jellyfin = {
        enable = true;
        user = "jellyfin";
        group = "jellyfin";
        openFirewall = true;
        dataDir = "/jellyfin/data/data";
        cacheDir = "/jellyfin/data/cache";
        logDir = "/jellyfin/data/logs";
        configDir = "/jellyfin/data/config";
        hardwareAcceleration = {
            enable = true;
            device = "/dev/dri/renderD128";
            type = "nvenc";
        };
    };
}
