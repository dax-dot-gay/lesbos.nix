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
                forward_ports = [
                    {
                        protocol = "both";
                        externalPort = 22000;
                        internalPort = 22000;
                    }
                    {
                        protocol = "both";
                        externalPort = 21027;
                        internalPort = 21027;
                    }
                    {
                        protocol = "both";
                        externalPort = 2122;
                        internalPort = 2122;
                    }
                    {
                        protocol = "tcp";
                        externalPort = 8193;
                        internalPort = 8193;
                    }
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
            srv-jellyfin = {
                description = "Separate VM for running Jellyfin specifically";
                address = "192.168.64.22";
                dns = [
                    "srv-jellyfin.lesbos.nix"
                    "jellyfin.srv"
                ];
            };
            srv-media-support = {
                description = "Services to support Jellyfin & other media servers";
                address = "192.168.64.23";
                dns = [
                    "srv-media-support.lesbos.nix"
                    "media-support.srv"
                ];
            };
            sys-datastore = {
                description = "Databases & S3";
                address = "192.168.64.13";
                dns = [
                    "sys-datastore.lesbos.nix"
                    "datastore.sys"
                ];
            };
            sys-auth = {
                description = "SSO authentication";
                address = "192.168.64.14";
                dns = [
                    "sys-auth.lesbos.nix"
                    "auth.sys"
                ];
            };
            srv-books = {
                description = "Ebooks & Audiobooks";
                address = "192.168.64.24";
                dns = [
                    "srv-books.lesbos.nix"
                    "books.srv"
                ];
            };
            sys-cicd = {
                description = "Woodpecker CI";
                address = "192.168.64.15";
                dns = [
                    "sys-cicd.lesbos.nix"
                    "cicd.sys"
                ];
            };
            srv-ttrpg = {
                description = "TTRPG-related services";
                address = "192.168.64.25";
                dns = [
                    "srv-ttrpg.lesbos.nix"
                    "ttrpg.srv"
                ];
            };
            srv-misc = {
                description = "Hosting for miscellaneous services with no specific requirements";
                address = "192.168.64.26";
                dns = [
                    "srv-misc.lesbos.nix"
                    "misc.srv"
                ];
            };
            peer-samantha = {
                description = "Samantha's ingress";
                address = "192.168.64.50";
                dns = [
                    "peer-samantha.lesbos.nix"
                    "samantha.peer"
                ];
            };
            srv-immich = {
                description = "Immich & related services";
                address = "192.168.64.27";
                dns = [
                    "srv-immich.lesbos.nix"
                    "immich.srv"
                ];
            };
        };
    };
}
