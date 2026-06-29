{ pkgs, ... }:
{
    virtualisation.oci-containers = {
        backend = "podman";
        containers.lidarr = {
            image = "lscr.io/linuxserver/lidarr:nightly";
            serviceName = "lidarr";
            environment = {
                PUID = "0";
                PGID = "0";
                TZ = "America/New_York";
            };
            volumes = [
                "/media-support/services/arrs/lidarr:/config"
                "/media-support/media/Songs:/music"
                "/media-support/downloads/downloads:/downloads"
                "${pkgs.ffmpeg}:/host-bin/ffmpeg"
            ];
            ports = [
                "0.0.0.0:8686:8686"
            ];
        };
        containers.musicseerr = {
            image = "ghcr.io/habirabbu/musicseerr:latest";
            serviceName = "musicseerr";
            environment = {
                PUID = "0";
                PGID = "0";
                TZ = "America/New_York";
                PORT = "8688";
            };
            ports = [
                "0.0.0.0:8688:8688"
            ];
            volumes = [
                "/media-support/services/musicseerr/config:/app/config"
                "/media-support/services/musicseerr/cache:/app/cache"
                "/media-support/media/Songs:/music:ro"
            ];
        };
    };
    networking.firewall.allowedTCPPorts = [ 8686 8688 ];
}
