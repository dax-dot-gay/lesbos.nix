{ config, ... }:
{
    lesbos.secrets.system = {
        "hookshot/registration.yml" = {
            mode = "0444";
        };
        "hookshot/passkey.pem" = {
            mode = "0444";
        };
    };

    lesbos.volumes.hookshot-data = {
        enable = true;
        source = {
            type = "share";
            name = "data";
            path = "/systems/srv-matrix/apps/hookshot";
            ensureSource.enable = true;
        };
        destination = "/var/lib/matrix-hookshot";
        strategy.bindMapped = {
            enable = true;
            permissions = "0777";
        };
        required_by = [ "matrix-hookshot.service" ];
    };

    services.redis = {
        enable = true;
        servers.hookshot = {
            enable = true;
            port = 2175;
        };
    };

    services.matrix-hookshot = {
        enable = true;
        registrationFile = config.sops.secrets."hookshot/registration.yml".path;
        settings = {
            passFile = config.sops.secrets."hookshot/passkey.pem".path;
            bridge = {
                domain = "dax.gay";
                url = "http://0.0.0.0:8008";
                mediaUrl = "https://matrix.dax.gay";
                port = 3993;
                bindAddress = "127.0.0.1";
            };
            logging = {
                level = "info";
                colorize = true;
                json = false;
                timestampFormat = "HH:mm:ss:SSS";
            };
            listeners = [
                {
                    port = 3000;
                    bindAddress = "0.0.0.0";
                    resources = [ "webhooks" ];
                }
                {
                    port = 3001;
                    bindAddress = "0.0.0.0";
                    resources = [ "metrics" ];
                }
                {
                    port = 3002;
                    bindAddress = "0.0.0.0";
                    resources = [ "widgets" ];
                }
            ];
            cache = {
                redisUri = "redis://localhost:2175";
            };
            encryption = {
                storagePath = "/var/lib/matrix-hookshot";
            };
            permissions = [
                {
                    actor = "@dax:dax.gay";
                    services = [
                        {
                            service = "*";
                            level = "admin";
                        }
                    ];
                }
            ];
            generic = {
                enabled = true;
                outbound = true;
                urlPrefix = "https://webhooks.matrix.dax.gay/";
                allowJsTransformationFunctions = true;
                waitForComplete = false;
                enableHttpGet = true;
                userIdPrefix = "hook_";
            };
            bot = {
                displayname = "Lesbos Notifications";
            };
            widgets = {
                roomSetupWidget = {
                    addOnInvite = true;
                };
                publicUrl = "https://webhooks.matrix.dax.gay/widgets/widgetapi/v1/static";
                branding = {
                    widgetTitle = "Hookshot Configuration";
                };
            };
        };
    };
}
