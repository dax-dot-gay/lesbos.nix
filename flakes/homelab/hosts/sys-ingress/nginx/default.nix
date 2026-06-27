{ config, ... }:
let
    preflight = import ./preflight.nix;
    clients = config.lesbos.homelab.net.clients;
in
{
    imports = [
        ./services
    ];
    security.acme = {
        acceptTerms = true;
        defaults.email = "me@dax.gay";
        defaults.group = "nginx";
        defaults.webroot = "/var/lib/acme/acme-challenge";
    };
    services.nginx = {
        enable = true;
        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        statusPage = true;

        # Only allow PFS-enabled ciphers with AES256
        sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";

        appendHttpConfig = ''
            # Add HSTS header with preloading to HTTPS requests.
            # Adding this header to HTTP requests is discouraged
            map $scheme $hsts_header {
                https   "max-age=31536000; includeSubdomains; preload";
            }
            add_header Strict-Transport-Security $hsts_header;

            proxy_hide_header Access-Control-Allow-Origin;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Host $host;

            map $http_origin $allowed_origin {
                default "";  # Block invalid origins
                ~^(https?):\/\/([a-zA-Z0-9-]+\.)*dax\.gay(:\d+)?$ $http_origin;  # Allow valid origins
            }

            add_header 'Access-Control-Allow-Origin' '*' always;
            proxy_buffers 8 512k;
            proxy_buffer_size 256k;
            proxy_busy_buffers_size 512k;
            large_client_header_buffers 8 256k;
        '';

        virtualHosts = {
            "dax.gay" = {
                enableACME = true;
                forceSSL = true;
                locations = {
                    "/.well-known/openid-configuration" = {
                        proxyPass = "http://${clients.srv-matrix.address}:8085/.well-known/openid-configuration";
                        proxyWebsockets = true;
                        extraConfig = preflight;
                    };
                    "/.well-known/matrix/client" = {
                        return = ''
                            200 '{
                                "m.homeserver": {
                                    "base_url": "https://matrix.dax.gay"
                                },
                                "m.identity_server": {
                                    "base_url": "https://vector.im"
                                },
                                "org.matrix.msc3575.proxy": {
                                    "url": "https://matrix.dax.gay"
                                }
                            }'
                        '';
                        extraConfig = ''
                            default_type application/json;
                        ''
                        + preflight;
                    };
                    "/.well-known/matrix/server" = {
                        return = ''
                            200 '{"m.server":"matrix.dax.gay:443"}'
                        '';
                        extraConfig = ''
                            default_type application/json;
                        ''
                        + preflight;
                    };
                    "/" = {
                        return = "301 https://github.com/dax-dot-gay";
                    };
                };
            };
            "grafana.lesbos.dax.gay" = {
                enableACME = true;
                forceSSL = true;
                locations."/" = {
                    proxyPass = "http://${clients.sys-monitoring.address}:8999";
                    proxyWebsockets = true;
                    recommendedProxySettings = true;
                };
            };
            "crafty.lesbos.dax.gay" = {
                enableACME = true;
                forceSSL = true;
                locations."/" = {
                    proxyPass = "https://${clients.srv-gameservers.address}:8443";
                    proxyWebsockets = true;
                    recommendedProxySettings = true;
                };
            };
            "sync.dax.gay" = {
                enableACME = true;
                forceSSL = true;
                locations."/" = {
                    proxyPass = "https://${clients.sys-storage.address}:8384";
                    proxyWebsockets = true;
                    recommendedProxySettings = true;
                };
            };
        };
    };
}
