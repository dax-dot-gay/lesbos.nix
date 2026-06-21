{ ... }:
{
    imports = [
        ./options.nix
        ./config.nix
    ];

    lesbos.homelab.net = {
        wan = {
            hostname = "lsb-sys-router";
            address = "192.168.0.64";
            prefix_length = 24;
            gateway = "192.168.0.1";
        };
        lan = {
            domain = "lesbos.nix";
            gateway = "192.168.64.1";
            prefix_length = 24;
            subnet = "192.168.64.0/24";
        };
        clients = {
            lsb-sys-router = {
                description = "Router, reference for other modules";
                address = "192.168.64.1";
            };
            sys-storage = {
                description = "Internal NAS and storage access provider";
                address = "192.168.64.10";
                dns = [
                    "sys-storage.lesbos.nix"
                    "storage.sys"
                ];
            };
            sys-ingress = {
                description = ''
                    System ingress methods
                    - Caddy, tailscale
                '';
                address = "192.168.64.11";
                dns = [
                    "sys-ingress.lesbos.nix"
                    "ingress.sys"
                ];
                forward_ports = [
                    {
                        protocol = "tcp";
                        externalPort = 80;
                        internalPort = 80;
                    }
                    {
                        protocol = "tcp";
                        externalPort = 443;
                        internalPort = 443;
                    }
                ];
            };
            srv-matrix = {
                description = ''
                    Matrix stack
                '';
                address = "192.168.64.20";
                dns = [
                    "srv-matrix.lesbos.nix"
                    "matrix.srv"
                ];
                forward_ports = [
                    {
                        protocol = "both";
                        externalPort = 8448;
                        internalPort = 8448;
                    }
                    {
                        protocol = "both";
                        externalPort = 7881;
                        internalPort = 7881;
                    }
                    {
                        protocol = "both";
                        externalPort = {
                            from = 48000;
                            to = 48999;
                        };
                        internalPort = {
                            from = 48000;
                            to = 48999;
                        };
                    }
                ];
            };
            sys-monitoring = {
                description = "Prometheus/Grafana monitoring";
                address = "192.168.64.12";
                dns = [
                    "sys-monitoring.lesbos.nix"
                    "monitoring.sys"
                ];
            };
            srv-gameservers = {
                description = "Hosting for gameservers";
                address = "192.168.64.21";
                dns = [
                    "srv-gameservers.lesbos.nix"
                    "gameservers.srv"
                ];
                forward_ports = [
                    { # Minecraft ports
                        protocol = "both";
                        externalPort = {
                            from = 25500;
                            to = 25600;
                        };
                        internalPort = {
                            from = 25500;
                            to = 25600;
                        };
                    }
                    { # Ports for extra services
                        protocol = "both";
                        externalPort = {
                            from = 24400;
                            to = 24500;
                        };
                        internalPort = {
                            from = 24400;
                            to = 24500;
                        };
                    }
                ];
            };
            sys-jellyfin = {
                description = "Separate VM for running Jellyfin specifically";
                address = "192.168.64.22";
                dns = [
                    "srv-jellyfin.lesbos.nix"
                    "jellyfin.srv"
                ];
            };
        };
    };
}
