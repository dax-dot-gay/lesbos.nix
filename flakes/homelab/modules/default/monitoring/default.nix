{ ... }:
{
    imports = [
        ./options.nix
        ./config.nix
    ];

    lesbos.monitoring = {
        defaultNodeCollectors = [
            "+systemd"
        ];
        scrapeInterval = "30s";
        systems = {
            lsb-sys-router = {
                exporters = {
                    dnsmasq = {
                        port = 9001;
                        extraConfig = {
                            leasesPath = "/var/lib/dnsmasq/net-lan/dhcp.leases";
                        };
                    };
                };
            };
            sys-storage = { };
            sys-ingress = {
                exporters = {
                    nginx = {
                        port = 9001;
                    };
                };
            };
            sys-monitoring = { };
            srv-matrix = {
                exporters = {
                    postgres = {
                        port = 9001;
                        extraConfig = {
                            dataSourceName = "user=postgres database=postgres host=/run/postgresql sslmode=disable";
                            runAsLocalSuperUser = true;
                        };
                    };
                };
            };
            srv-gameservers = { };
            srv-jellyfin = { };
            srv-media-support = {
                exporters = {
                    exportarr-radarr = {
                        port = 9001;
                        user = "root";
                        group = "root";
                        extraConfig = {
                            apiKeyFile = "/run/secrets/arr/radarr.key";
                        };
                    };
                    exportarr-sonarr = {
                        port = 9002;
                        user = "root";
                        group = "root";
                        extraConfig = {
                            apiKeyFile = "/run/secrets/arr/sonarr.key";
                        };
                    };
                };
            };
            sys-datastore = {
                exporters = {
                    postgres = {
                        port = 9001;
                        extraConfig = {
                            dataSourceName = "user=postgres database=postgres host=/run/postgresql sslmode=disable";
                            runAsLocalSuperUser = true;
                        };
                    };
                };
            };
            sys-auth = {};
            srv-books = {};
            sys-cicd = {};
        };
    };
}
