{ config, pkgs, ... }:
{
    environment.systemPackages = [
        (pkgs.writeShellScriptBin "woodpecker-cli" ''
            env WOODPECKER_SERVER="https://woodpecker.dax.gay" WOODPECKER_TOKEN="$(cat ${config.sops.secrets.woodpecker-token.path})" ${pkgs.woodpecker-cli}/bin/woodpecker-cli $@
        '')
    ];
    lesbos.secrets.system = {
        "woodpecker.env" = {
            owner = "woodpecker";
            group = "woodpecker";
            mode = "0400";
        };
        "woodpecker-token" = {
            owner = "root";
            group = "root";
            mode = "0444";
        };
    };
    services.woodpecker-server = {
        enable = true;
        environment = {
            WOODPECKER_HOST = "https://woodpecker.dax.gay";
            WOODPECKER_OPEN = "false";
            WOODPECKER_ADMIN = "dax-dot-gay";
            WOODPECKER_SERVER_ADDR = "0.0.0.0:3007";
            WOODPECKER_GRPC_ADDR = ":9800";
        };
        environmentFile = [ config.sops.secrets."woodpecker.env".path ];
    };
    services.woodpecker-agents.agents."docker" = {
        enable = true;
        extraGroups = [ "podman" ];
        environment = {
            WOODPECKER_SERVER = "localhost:9800";
            WOODPECKER_BACKEND = "docker";
            DOCKER_HOST = "unix:///run/podman/podman.sock";
            WOODPECKER_MAX_WORKFLOWS = "4";
        };
        environmentFile = [ config.sops.secrets."woodpecker.env".path ];
    };
    virtualisation.podman = {
        enable = true;
        defaultNetwork.settings = {
            dns_enabled = true;
        };
    };
    networking.firewall.interfaces."podman0" = {
        allowedUDPPorts = [ 53 ];
        allowedTCPPorts = [ 53 ];
    };
    networking.firewall.allowedTCPPorts = [ 3007 ];
    systemd.services = {
        woodpecker-server.serviceConfig = {
            User = "woodpecker";
            Group = "woodpecker";
        };
        woodpecker-agent-docker.serviceConfig = {
            User = "woodpecker";
            Group = "podman";
        };
    };
}
