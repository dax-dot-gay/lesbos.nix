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
        /*"deluge.media.dax.gay" = {
            enableACME = true;
            forceSSL = true;
            locations."/" = {
                proxyPass = "http://${clients.srv-media-support.address}:8112";
                proxyWebsockets = true;
                extraConfig = preflight;
            };
        };
        "sonarr.media.dax.gay" = {
            enableACME = true;
            forceSSL = true;
            locations."/" = {
                proxyPass = "http://${clients.srv-media-support.address}:8989";
                proxyWebsockets = true;
                extraConfig = preflight;
            };
        };
        "radarr.media.dax.gay" = {
            enableACME = true;
            forceSSL = true;
            locations."/" = {
                proxyPass = "http://${clients.srv-media-support.address}:7878";
                proxyWebsockets = true;
                extraConfig = preflight;
            };
        };*/
        /*"prowlarr.media.dax.gay" = {
            enableACME = true;
            forceSSL = true;
            locations."/" = {
                proxyPass = "http://${clients.srv-media-support.address}:9696";
                proxyWebsockets = true;
                extraConfig = preflight;
            };
        };*/
    };
}
