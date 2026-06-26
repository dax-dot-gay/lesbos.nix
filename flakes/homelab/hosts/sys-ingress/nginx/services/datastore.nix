{ config, ... }:
let
    preflight = import ../preflight.nix;
    clients = config.lesbos.homelab.net.clients;
in
{
    services.nginx.virtualHosts = {
        "pgadmin.store.dax.gay" = {
            enableACME = true;
            forceSSL = true;
            locations = {
                "/" = {
                    proxyPass = "http://${clients.sys-datastore.address}:5050";
                    proxyWebsockets = true;
                    extraConfig = preflight;
                };
            };
        };
    };
}
