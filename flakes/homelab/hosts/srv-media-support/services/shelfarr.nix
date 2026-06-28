{ config, lib, ... }:
with lib;
{
    lesbos.secrets.system."shelfarr/key" = {
        owner = "shelfarr";
        group = "shelfarr";
        mode = "0400";
    };
    sops.templates."shelfarr.env" = {
        owner = "shelfarr";
        group = "shelfarr";
        mode = "0400";
        content = ''
            RAILS_MASTER_KEY=${config.sops.placeholder."shelfarr/key"}
        '';
    };

    virtualisation.oci-containers = {
        backend = "podman";
        containers.shelfarr = {
            image = "ghcr.io/pedro-revez-silva/shelfarr:latest";
            serviceName = "shelfarr";
            ports = [
                "0.0.0.0:5056:80"
            ];
            environment = {
                PUID = "${toString config.users.users.shelfarr.uid}";
                PGID = "${toString config.users.groups.media-service.gid}";
                CHOWN_ON_START = "never";
                SOLID_QUEUE_IN_PUMA = "1";
            };
            environmentFiles = [ config.sops.templates."shelfarr.env".path ];
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
