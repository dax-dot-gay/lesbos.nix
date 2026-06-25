{ config, lib, ... }: with lib;
{
    lesbos.secrets.system."seerr/seerr.key" = {
        mode = "0400";
        owner = "seerr";
        group = "seerr";
    };
    sops.templates."seerr.env" = {
        mode = "0400";
        owner = "seerr";
        group = "seerr";
        content = ''
            API_KEY=${config.sops.placeholder."seerr/seerr.key"}
        '';
    };
    virtualisation.oci-containers = {
        backend = "podman";
        containers.seerr = {
            autoStart = true;
            image = "ghcr.io/seerr-team/seerr:latest";
            serviceName = "seerr";
            environment = {
                LOG_LEVEL = "debug";
                TZ = "America/New_York";
                PORT = "5055";
            };
            environmentFiles = [
                config.sops.templates."seerr.env".path
            ];
            ports = [
                "0.0.0.0:5055:5055"
            ];
            volumes = [
                "/media-support/services/seerr:/app/config"
            ];
            user = "seerr:media-service";
            extraOptions = [
                "--health-cmd=\"wget --no-verbose --tries=1 --spider http://localhost:5055/api/v1/settings/public || exit 1\""
                "--health-start-period=20s"
                "--health-timeout=3s"
                "--health-interval=15s"
                "--health-retries=3"
                "--uidmap=1000:${toString config.users.users.seerr.uid}"
                "--gidmap=1000:${toString config.users.groups.media-service.gid}"
            ];
        };
    };
    systemd.timers.podman-auto-update.wantedBy = [ "timers.target" ];
}
