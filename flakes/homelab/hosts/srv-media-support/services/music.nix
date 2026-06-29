{ config, ... }:
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
            ];
            ports = [
                "0.0.0.0:8686:8686"
            ];
        };
    };
}
