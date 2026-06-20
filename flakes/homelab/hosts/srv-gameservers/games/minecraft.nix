{ ... }:
{
    lesbos = {
        volumes = {
            crafty-controller-minecraft = {
                enable = true;
                source = {
                    type = "share";
                    name = "data";
                    path = "/systems/srv-gameservers/games/minecraft";
                    ensureSource = {
                        enable = true;
                        user = "crafty";
                        group = "crafty";
                        mode = "0770";
                    };
                };
                destination = "/var/lib/gameservers/crafty-controller/minecraft";
                required_by = [ "podman-crafty-controller.service" ];
                strategy.bind.enable = true;
            };
            crafty-controller-internal = {
                enable = true;
                source = {
                    type = "share";
                    name = "data";
                    path = "/systems/srv-gameservers/managers/crafty-controller";
                    ensureSource = {
                        enable = true;
                        user = "crafty";
                        group = "crafty";
                        mode = "0770";
                    };
                };
                destination = "/var/lib/gameservers/crafty-controller/app";
                required_by = [ "podman-crafty-controller.service" ];
                strategy.sync = {
                    enable = true;
                    user = "crafty";
                    group = "crafty";
                    mode = "0700";
                    restoration = true;
                    timerConfig = {
                        OnActiveSec = "2h";
                    };
                };
            };
        };
    };
    virtualisation.oci-containers.containers.crafty-controller = {
        image = "registry.gitlab.com/crafty-controller/crafty-4:latest";
        autoStart = true;
        environment = {
            TZ = "America/New_York";
        };
        ports = [
            "0.0.0.0:8443:8443"
            "0.0.0.0:24400-24500:24400-24500"
            "0.0.0.0:25500-25600:25500-25600"
        ];
        volumes = [
            "/var/lib/gameservers/crafty-controller/minecraft/backups:/crafty/backups"
            "/var/lib/gameservers/crafty-controller/minecraft/logs:/crafty/logs"
            "/var/lib/gameservers/crafty-controller/minecraft/servers:/crafty/servers"
            "/var/lib/gameservers/crafty-controller/app:/crafty/app/config"
            "/var/lib/gameservers/crafty-controller/minecraft/import:/crafty/import"
        ];
        user = "crafty";
    };
    users = {
        users.crafty = {
            isSystemUser = true;
            group = "crafty";
        };
        groups.crafty = { };
    };
    networking.firewall = {
        allowedTCPPorts = [ 8443 ];
        allowedUDPPorts = [ 8443 ];
        allowedTCPPortRanges = [
            {
                from = 25500;
                to = 25600;
            }
            {
                from = 24400;
                to = 24500;
            }
        ];
        allowedUDPPortRanges = [
            {
                from = 25500;
                to = 25600;
            }
            {
                from = 24400;
                to = 24500;
            }
        ];
    };
}
