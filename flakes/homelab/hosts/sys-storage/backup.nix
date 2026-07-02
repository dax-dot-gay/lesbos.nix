{ config, ... }:
{
    networking.firewall.allowedTCPPorts = [
        2122
        3000
    ];
    lesbos.secrets.system."borgbackup.env" = {
        owner = "borgwarehouse";
        group = "borgwarehouse";
        mode = "0440";
    };
    virtualisation.oci-containers = {
        backend = "podman";
        containers = {
            borgwarehouse = {
                image = "borgwarehouse/borgwarehouse:v3.4.0";
                ports = [
                    "0.0.0.0:2122:22"
                    "0.0.0.0:3000:3000"
                ];
                volumes = [
                    "/borgbackup/app/app:/home/borgwarehouse/app/config"
                    "/borgbackup/app/ssh/host:/home/borgwarehouse/.ssh"
                    "/borgbackup/app/ssh/client:/etc/ssh"
                    "/borgbackup/backups:/home/borgwarehouse/repos"
                ];
                environment = {
                    WEB_SERVER_PORT = "3000";
                    SSH_SERVER_PORT = "2122";
                    FQDN = "backups.dax.gay";
                    BETTER_AUTH_URL = "https://backups.dax.gay";
                    PUID = "348";
                    PGID = "348";
                };
                environmentFiles = [
                    config.sops.secrets."borgbackup.env".path
                ];
                user = "borgwarehouse:borgwarehouse";
                serviceName = "borgwarehouse";
            };
        };
    };
}
