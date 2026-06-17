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
            sys-storage = {
                description = "Internal NAS and shared data provider";
                address = "192.168.64.10";
                dns = "storage.sys.lesbos.nix";
            };
            sys-ingress = {
                description = ''
                    System ingress methods
                    - Caddy, tailscale
                '';
                address = "192.168.64.11";
                dns = "ingress.sys.lesbos.nix";
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
        };
    };
}
