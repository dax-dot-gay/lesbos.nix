{ config, lib, ... }:
with lib;
let
    cfg = config.lesbos.monitoring;
    exporterType = types.submodule (
        { config, ... }:
        {
            options = {
                port = mkOption {
                    description = "Port to listen on (Listens on 0.0.0.0:[port])";
                    type = types.port;
                };
                user = mkOption {
                    description = "User name under which this exporter shall be run.";
                    type = types.str;
                    default = "${config._module.args.name}-exporter";
                };
                group = mkOption {
                    description = "Group name under which this exporter shall be run.";
                    type = types.str;
                    default = "${config._module.args.name}-exporter";
                };
                extraFlags = mkOption {
                    description = "Extra command-line flags to pass to the exporter";
                    type = types.listOf types.str;
                    default = [ ];
                };
                extraConfig = mkOption {
                    description = "Extra config options for this specific exporter";
                    type = types.attrs;
                    default = { };
                };
            };
        }
    );

    systemType = types.submodule (
        { config, ... }:
        {
            options = {
                node = {
                    collectors = mkOption {
                        description = "Node collectors (prefixed with + or - to enable or disable).";
                        type = types.listOf types.str;
                        default = cfg.defaultNodeCollectors;
                    };
                    port = mkOption {
                        description = "Port to run the node exporter on";
                        type = types.port;
                        default = 9000;
                    };
                };
                comin = {
                    enable = mkOption {
                        description = "Whether to enable the comin exporter for this node";
                        type = types.bool;
                        default = true;
                    };
                    port = mkOption {
                        description = "Port to run the comin exporter on";
                        type = types.port;
                        default = 9100;
                    };
                };
                exporters = mkOption {
                    description = "Submodule of exporters mapped to their exporter type.";
                    type = types.attrsOf exporterType;
                    default = { };
                    example = {
                        nginx = {
                            port = 9001;
                            user = "nginx-exporter";
                            group = "nginx-exporter";
                            extraConfig = {
                                scrapeUri = "http://localhost/nginx_status";
                            };
                        };
                    };
                };
                custom-exporters = mkOption {
                    description = "Configuration of exporters not specified in `services.prometheus.exporters.*`";
                    type = types.attrsOf (
                        types.submodule (
                            { config, ... }:
                            {
                                name = mkOption {
                                    description = "Name of this exporter";
                                    type = types.str;
                                    default = config._module.args.name;
                                };
                                port = mkOption {
                                    description = "Port to open for this exporter";
                                    type = types.port;
                                };
                            }
                        )
                    );
                    default = { };
                };
            };
        }
    );
in
{
    options = {
        lesbos.monitoring = {
            defaultNodeCollectors = mkOption {
                description = "Default node collectors (prefixed with + or - to enable or disable)";
                type = types.listOf types.str;
                default = [ ];
            };
            scrapeInterval = mkOption {
                description = "Scrape interval in `systemd.time(7)` format";
                type = types.str;
                default = "10s";
                example = "1m";
            };
            systems = mkOption {
                description = "Systems to configure monitoring for";
                type = types.attrsOf systemType;
                default = { };
            };
        };
    };
}
