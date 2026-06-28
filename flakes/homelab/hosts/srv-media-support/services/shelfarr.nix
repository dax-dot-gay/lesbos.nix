{ config, ... }:
{
    virtualisation.oci-containers = {
        backend = "podman";
        containers.shelfarr = {
            image = "ghcr.io/pedro-revez-silva/shelfarr:latest";
            serviceName = "shelfarr";
            ports = [
                "0.0.0.0:5056:80"
            ];
            environment = {
                PUID = "0";
                PGID = "0";
                CHOWN_ON_START = "never";
                SOLID_QUEUE_IN_PUMA = "1";
            };
            volumes = [
                "/media-support/services/shelfarr/data:/rails/storage"
                "/media-support/media/Audiobooks:/audiobooks"
                "/media-support/media/Library/shelfarr:/ebooks"
                "/media-support/services/shelfarr/downloads:/downloads"
            ];
        };
    };

    networking.firewall.allowedTCPPorts = [ 5056 ];
}
