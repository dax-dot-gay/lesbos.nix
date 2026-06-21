{ config, ... }:
let
    preflight = import ../preflight.nix;
    clients = config.lesbos.homelab.net.clients;
in
{
    services.nginx.virtualHosts = {
        "jellyfin.dax.gay" = {
            enableACME = true;
            forceSSL = true;
            locations."/" = {
                proxyPass = "http://${clients.srv-jellyfin.address}:8096";
                proxyWebsockets = true;
                extraConfig = preflight;
            };
        };
    };
}
