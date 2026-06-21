{ config, ... }:
let
    preflight = import ../preflight.nix;
    clients = config.lesbos.homelab.net.clients;
in
{
    services.nginx.virtualHosts = {
        "auth.matrix.dax.gay" = {
            enableACME = true;
            forceSSL = true;
            locations."/" = {
                proxyPass = "http://${clients.srv-matrix.address}:8085";
                proxyWebsockets = true;
                extraConfig = preflight;
            };
        };
        "matrix.dax.gay" = {
            enableACME = true;
            forceSSL = true;
            serverName = "matrix.dax.gay";
            locations = {
                "~ ^/_matrix/client/(.*)/(login|logout|refresh)" = {
                    proxyPass = "http://${clients.srv-matrix.address}:8085";
                    proxyWebsockets = true;
                    extraConfig = preflight;
                };
                "/.well-known/openid-configuration" = {
                    proxyPass = "http://${clients.srv-matrix.address}:8085/.well-known/openid-configuration";
                    proxyWebsockets = true;
                    extraConfig = preflight;
                };
                "/" = {
                    proxyPass = "http://${clients.srv-matrix.address}:8008";
                    proxyWebsockets = true;
                    extraConfig = preflight;
                };
            };
        };
        "admin.matrix.dax.gay" = {
            enableACME = true;
            forceSSL = true;
            locations = {
                "/" = {
                    proxyPass = "http://${clients.srv-matrix.address}:9080";
                    proxyWebsockets = true;
                    extraConfig = preflight;
                };
            };
        };
    };
}
