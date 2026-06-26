{
    config,
    pkgs,
    lib,
    ...
}:
{
    lesbos.secrets.system = {
        "authentik/main/secret_key" = {
            owner = "authentik";
            group = "authentik";
            mode = "0400";
        };
        "authentik/main/email_password" = {
            owner = "authentik";
            group = "authentik";
            mode = "0400";
        };
        "authentik/main/bootstrap/email" = {
            owner = "authentik";
            group = "authentik";
            mode = "0400";
        };
        "authentik/main/bootstrap/password" = {
            owner = "authentik";
            group = "authentik";
            mode = "0400";
        };
        "authentik/main/bootstrap/token" = {
            owner = "authentik";
            group = "authentik";
            mode = "0400";
        };
        "authentik/main/database/host" = {
            owner = "authentik";
            group = "authentik";
            mode = "0400";
        };
        "authentik/main/database/name" = {
            owner = "authentik";
            group = "authentik";
            mode = "0400";
        };
        "authentik/main/database/password" = {
            owner = "authentik";
            group = "authentik";
            mode = "0400";
        };
        "authentik/main/database/user" = {
            owner = "authentik";
            group = "authentik";
            mode = "0400";
        };
        "authentik/ldap/token" = {
            owner = "authentik";
            group = "authentik";
            mode = "0400";
        };
        "authentik/proxy/token" = {
            owner = "authentik";
            group = "authentik";
            mode = "0400";
        };
    };

    sops.templates =
        let
            pl = config.sops.placeholder;
        in
        {
            "authentik.env" = {
                owner = "authentik";
                group = "authentik";
                mode = "0400";
                content = ''
                    AUTHENTIK_SECRET_KEY=${pl."authentik/main/secret_key"}
                    AUTHENTIK_EMAIL__PASSWORD=${pl."authentik/main/email_password"}
                    AUTHENTIK_BOOTSTRAP_PASSWORD=${pl."authentik/main/bootstrap/password"}
                    AUTHENTIK_BOOTSTRAP_EMAIL=${pl."authentik/main/bootstrap/email"}
                    AUTHENTIK_BOOTSTRAP_TOKEN=${pl."authentik/main/bootstrap/token"}
                    AUTHENTIK_POSTGRESQL__HOST=${pl."authentik/main/database/host"}
                    AUTHENTIK_POSTGRESQL__NAME=${pl."authentik/main/database/name"}
                    AUTHENTIK_POSTGRESQL__PASSWORD=${pl."authentik/main/database/password"}
                    AUTHENTIK_POSTGRESQL__USER=${pl."authentik/main/database/user"}
                    AUTHENTIK_LISTEN__TRUSTED_PROXY_CIDRS=192.168.64.0/24
                    AUTHENTIK_LISTEN__HTTP=0.0.0.0:9000
                    AUTHENTIK_LISTEN__METRICS=0.0.0.0:9300
                '';
            };
            "authentik-ldap.env" = {
                owner = "authentik";
                group = "authentik";
                mode = "0400";
                content = ''
                    AUTHENTIK_TOKEN=${pl."authentik/ldap/token"}
                    AUTHENTIK_HOST=https://auth.dax.gay
                    AUTHENTIK_INSECURE=False
                '';
            };
            "authentik-proxy.env" = {
                owner = "authentik";
                group = "authentik";
                mode = "0400";
                content = ''
                    AUTHENTIK_TOKEN=${pl."authentik/proxy/token"}
                    AUTHENTIK_HOST=https://auth.dax.gay
                    AUTHENTIK_INSECURE=False
                '';
            };
        };

    services = {
        authentik = {
            enable = true;
            createDatabase = false;
            environmentFile = config.sops.templates."authentik.env".path;
            settings = {
                storage.media.file = lib.mkOverride 10 { path = "/authentik/media"; };
                media.enableUpload = true;
                email = {
                    host = "mail.smtp2go.com";
                    port = 443;
                    username = "auth.dax.gay";
                    use_tls = false;
                    use_ssl = true;
                    from = "Lesbos SSO <sso@dax.gay>";
                };
                avatars = "initials";
                disable_startup_analytics = true;
                log_level = "debug";
                cookie_domain = "dax.gay";
            };
            nginx.enable = false;
        };
        authentik-ldap = {
            enable = true;
            environmentFile = config.sops.templates."authentik-ldap.env".path;
        };

        authentik-proxy = {
            enable = true;
            environmentFile = config.sops.templates."authentik-proxy.env".path;
            listenHTTP = "0.0.0.0:9005";
            listenHTTPS = "0.0.0.0:9004";
        };
    };

    systemd.services.authentik.serviceConfig.ReadWritePaths = [
        "/authentik/blueprints"
        "/authentik/templates"
        "/authentik/media"
    ];
    systemd.services.authentik-worker.serviceConfig.ReadWritePaths = [
        "/authentik/blueprints"
        "/authentik/templates"
        "/authentik/media"
    ];
    systemd.services.authentik-migrate.serviceConfig.ReadWritePaths = [
        "/authentik/blueprints"
        "/authentik/templates"
        "/authentik/media"
    ];

    networking.firewall.allowedTCPPorts = [
        9000
        9300
        9004
        9005
        3389
    ];
}
