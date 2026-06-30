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
        };
        "prowlarr.media.dax.gay" = {
            enableACME = true;
            forceSSL = true;
            locations."/" = {
                proxyPass = "http://${clients.srv-media-support.address}:9696";
                proxyWebsockets = true;
                extraConfig = preflight;
            };
        };
        "bazarr.media.dax.gay" = {
            enableACME = true;
            forceSSL = true;
            locations."/" = {
                proxyPass = "http://${clients.srv-media-support.address}:6767";
                proxyWebsockets = true;
                extraConfig = preflight;
            };
        };
        "request.jellyfin.dax.gay" = {
            enableACME = true;
            forceSSL = true;
            locations."/" = {
                proxyPass = "http://${clients.srv-media-support.address}:5055";
                proxyWebsockets = true;
                extraConfig = preflight;
            };
        };
        "library.dax.gay" = {
            enableACME = true;
            forceSSL = true;
            locations."/" = {
                proxyPass = "http://${clients.srv-books.address}:6060";
                proxyWebsockets = true;
                extraConfig = preflight + ''
                    proxy_set_header Host $host;
                    proxy_set_header X-Real-IP $remote_addr;
                    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                    proxy_set_header X-Forwarded-Host $host;
                    proxy_set_header X-Forwarded-Proto $scheme;
                    proxy_set_header X-Forwarded-Port $server_port;

                    proxy_buffer_size 128k;
                    proxy_buffers 4 256k;
                    proxy_busy_buffers_size 256k;
                    large_client_header_buffers 8 32k;
                '';
            };
        };
        "request.library.dax.gay" = {
            enableACME = true;
            forceSSL = true;
            locations."/" = {
                proxyPass = "http://${clients.srv-media-support.address}:5056";
                proxyWebsockets = true;
                extraConfig = preflight;
            };
        };
        "lidarr.media.dax.gay" = {
            enableACME = true;
            forceSSL = true;
            locations."/" = {
                proxyPass = "http://${clients.srv-media-support.address}:8686";
                proxyWebsockets = true;
                extraConfig = preflight;
            };
        };
        "seek.dl.dax.gay" = {
            enableACME = true;
            forceSSL = true;
            locations."/" = {
                proxyPass = "http://${clients.srv-media-support.address}:5030";
                proxyWebsockets = true;
                extraConfig = preflight;
            };
        };
        "torrent.dl.dax.gay" = {
            enableACME = true;
            forceSSL = true;
            locations."/" = {
                proxyPass = "http://${clients.srv-media-support.address}:8080";
                proxyWebsockets = true;
                extraConfig = preflight;
            };
        };
        "music-request.jellyfin.dax.gay" = {
            enableACME = true;
            forceSSL = true;
            locations."/" = {
                proxyPass = "http://${clients.srv-media-support.address}:8688";
                proxyWebsockets = true;
                extraConfig = preflight;
            };
        };
    };
}
