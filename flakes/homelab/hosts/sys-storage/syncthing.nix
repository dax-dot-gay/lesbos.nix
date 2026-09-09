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
}
