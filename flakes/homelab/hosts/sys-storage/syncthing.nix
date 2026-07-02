{ config, ... }:
{
    lesbos.secrets.system."syncthing/password" = {
        owner = "syncthing";
        group = "syncthing";
        mode = "0400";
    };
    services.syncthing = {
        enable = true;
        guiAddress = "0.0.0.0:8384";
        guiPasswordFile = config.sops.secrets."syncthing/password".path;
        settings = {
            gui.user = "dax";
            folders = {
                secrets = {
                    path = "/syncthing/shared-folders/secrets";
                };
                misc = {
                    path = "/syncthing/shared-folders/misc";
                };
            };
        };
        dataDir = "/syncthing/service";
    };
    networking.firewall.allowedTCPPorts = [
        22000
        21027
        8384
    ];
    networking.firewall.allowedUDPPorts = [
        22000
        21027
    ];
    systemd.services.syncthing-init.enable = false;
}
