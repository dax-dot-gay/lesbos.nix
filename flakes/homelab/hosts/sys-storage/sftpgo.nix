{
    config,
    pkgs,
    lib,
    ...
}:
let
    pre-login = pkgs.writeShellScriptBin "pre-login" ''
        /run/current-system/sw/bin/rm -rf /sftpgo/app/login.json
        echo "$SFTPGO_LOGIND_USER" > /sftpgo/app/login.json
        USER_ID="$(/run/current-system/sw/bin/jq .id /sftpgo/app/login.json)"
        USER_NAME="$(/run/current-system/sw/bin/jq -r .username /sftpgo/app/login.json)"

        if [ $USER_ID -eq 0 ]; then
            echo "$SFTPGO_LOGIND_PROTOCOL" > /sftpgo/app/protocol
            if [ $SFTPGO_LOGIND_PROTOCOL = "OIDC" ]; then
                JQ_OUT=$(/run/current-system/sw/bin/printf '{"status": 1,"username": "%s","has_password": false,"permissions": {"/": ["*"], "/shares/public": ["list", "download"]},"groups": [{"type": 1, "name": "default"}], "home_dir": "/sftpgo/shares/homes/%s"}' "''${USER_NAME}")

                echo -e $JQ_OUT
            else
                echo ""
            fi
        else
            echo ""
        fi

        #/run/current-system/sw/bin/rm -rf /sftpgo/app/login.json
    '';
in
{
    lesbos.secrets.system = {
        "sftpgo/oidc_client_secret" = {
            mode = "0400";
            owner = "sftpgo";
            group = "sftpgo";
        };
    };

    environment.systemPackages = [
        pkgs.jq
    ];

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
        sftpgo-public = {
            enable = true;
            source = {
                type = "share";
                name = "data";
                path = "/homes/public";
                ensureSource.enable = true;
            };
            destination = "/sftpgo/shares/public";
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
        extraReadWriteDirs = ["/sftpgo"];
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
                        disabled_login_methods = 9;
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
                            debug = true;
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
                pre_login_hook = "${pre-login}/bin/pre-login";
            };
        };
    };
}
