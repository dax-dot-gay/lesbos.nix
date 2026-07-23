{
    config,
    pkgs,
    lib,
    ...
}:
{
    lesbos.secrets.system = {
        "sftpgo/oidc_client_secret" = {
            mode = "0400";
            owner = "sftpgo";
            group = "sftpgo";
        };
    };

    lesbos.volumes = {
        sftpgo-app = {
            enable = true;
            source = {
                type = "share";
                name = "data";
                path = "/systems/sys-storage/sftpgo";
                ensureSource.enable = true;
            };
            destination = "/sftpgo/app";
            strategy.bindMapped = {
                enable = true;
                user = "sftpgo";
                group = "sftpgo";
                permissions = "0770";
            };
            required_by = [ "sftpgo.service" ];
        };
        sftpgo-homes = {
            enable = true;
            source = {
                type = "share";
                name = "data";
                path = "/homes";
                ensureSource.enable = true;
            };
            destination = "/sftpgo/shares/homes";
            strategy.bindMapped = {
                enable = true;
                user = "sftpgo";
                group = "sftpgo";
                permissions = "0770";
            };
            required_by = [ "sftpgo.service" ];
        };
        sftpgo-root = {
            enable = true;
            source = {
                type = "share";
                name = "data";
                path = "/";
            };
            destination = "/sftpgo/shares/root";
            strategy.bindMapped = {
                enable = true;
                user = "sftpgo";
                group = "sftpgo";
                permissions = "0770";
            };
            required_by = [ "sftpgo.service" ];
        };
    };

    networking.firewall.allowedTCPPorts = [
        8192
        8193
    ];
    services.sftpgo = {
        enable = true;
        user = "sftpgo";
        group = "sftpgo";
        dataDir = "/sftpgo/app";
        settings = {
            httpd = {
                cookie_lifetime = 720;
                hide_support_link = true;
                bindings = [
                    {
                        port = 8192;
                        address = "0.0.0.0";
                        enable_web_admin = true;
                        enable_web_client = true;
                        enable_rest_api = true;
                        disabled_login_methods = 8;
                        proxy_allowed = [
                            "192.168.64.0/24"
                        ];
                        oidc = {
                            config_url = "https://auth.dax.gay/application/o/sftpgo/";
                            client_id = "XKcmdext7KdObjQGpKU72Mp7TkAxCh2kmxJBBc04";
                            client_secret_file = "${config.sops.secrets."sftpgo/oidc_client_secret".path}";
                            redirect_base_url = "https://fs.dax.gay";
                            scopes = [
                                "openid"
                                "profile"
                                "email"
                            ];
                            username_field = "preferred_username";
                            implicit_roles = true;
                        };
                    }
                ];
            };
            sftpd.bindings = [
                {
                    address = "0.0.0.0";
                    port = 8193;
                }
            ];
            data_provider = {
                driver = "bolt";
                name = "sftpgo.bolt.db";
            };
        };
    };
}
