{ config, ... }:
{
    lesbos.secrets.system = {
        "foundry/username" = { };
        "foundry/password" = { };
        "foundry/admin" = { };
    };
    sops.templates."foundry.env" = {
        owner = "root";
        group = "root";
        mode = "0444";
        content =
            let
                pl = config.sops.placeholder;
            in
            ''
                FOUNDRY_USERNAME=${pl."foundry/username"}
                FOUNDRY_PASSWORD=${pl."foundry/password"}
                FOUNDRY_ADMIN_KEY=${pl."foundry/admin"}
            '';
    };
    virtualisation.oci-containers = {
        backend = "podman";
        containers.foundry = {
            serviceName = "foundry";
            image = "ghcr.io/felddy/foundryvtt:latest";
            hostname = "srv-ttrpg-foundry";
            volumes = [
                "/foundryvtt:/data"
            ];
            ports = [
                "0.0.0.0:30000:30000"
            ];
            environmentFiles = [
                config.sops.templates."foundry.env".path
            ];
            environment = {
                FOUNDRY_TELEMETRY = "true";
                TZ = "America/New_York";
            };
        };
    };
    networking.firewall.allowedTCPPorts = [ 30000 ];
}
