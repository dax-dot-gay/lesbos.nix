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
        containers.yubal = {
            image = "ghcr.io/guillevc/yubal:latest";
            serviceName = "yubal";
            ports = ["0.0.0.0:8690:8690"];
            environment = {
                PUID = "0";
                PGID = "0";
                YUBAL_SCHEDULER_CRON = "0 0 * * *";
                YUBAL_DOWNLOAD_UGC = "false";
                YUBAL_TZ = "US/Eastern";
                YUBAL_AUDIO_FORMAT = "mp3";
                YUBAL_AUDIO_QUALITY = "0";
                YUBAL_PORT = "8690";
            };
            volumes = [
                "/media-support/services/yubal:/app/config"
                "/media-support/media/YoutubeSongs:/app/data"
            ];
        };
    };
    networking.firewall.allowedTCPPorts = [ 8686 8688 8690 ];
}
