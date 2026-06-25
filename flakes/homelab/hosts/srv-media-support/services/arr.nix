{ config, lib, ... }:
with lib;
let
    mkArr = name: port: {
        enable = true;
        dataDir = if name == "prowlarr" then "/var/lib/prowlarr" else "/media-support/services/arrs/${name}";
        environmentFiles = [
            config.sops.templates."${name}.env".path
        ];
        openFirewall = true;
        settings = {
            log.analyticsEnabled = false;
            app.instancename = "lesbos-${name}";
            update.mechanism = "external";
            server = {
                port = port;
                bindaddress = "0.0.0.0";
            };
        };
    } // (optionalAttrs (name != "prowlarr") {
        user = name;
        group = "acquisition";
    });
in
{
    lesbos.secrets.system = {
        "arr/sonarr.key" = {
            owner = "sonarr";
            group = "sonarr";
            mode = "0400";
        };
        "arr/radarr.key" = {
            owner = "radarr";
            group = "radarr";
            mode = "0400";
        };
        "arr/prowlarr.key" = {
            owner = "prowlarr";
            group = "prowlarr";
            mode = "0400";
        };
    };
    sops.templates = {
        "sonarr.env" = {
            owner = "sonarr";
            group = "sonarr";
            mode = "0400";
            content = "SONARR__AUTH__APIKEY=${config.sops.placeholder."arr/sonarr.key"}";
        };
        "radarr.env" = {
            owner = "radarr";
            group = "radarr";
            mode = "0400";
            content = "RADARR__AUTH__APIKEY=${config.sops.placeholder."arr/radarr.key"}";
        };
        "prowlarr.env" = {
            owner = "prowlarr";
            group = "prowlarr";
            mode = "0400";
            content = "PROWLARR__AUTH__APIKEY=${config.sops.placeholder."arr/prowlarr.key"}";
        };
    };

    services = {
        sonarr = mkArr "sonarr" 8989;
        radarr = mkArr "radarr" 7878;
        prowlarr = mkArr "prowlarr" 9696;
    };
}
