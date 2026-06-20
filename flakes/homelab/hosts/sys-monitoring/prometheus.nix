{ config, lib, ... }:
with lib;
let
    cfg = config.lesbos.monitoring;
in
{
    lesbos.volumes.prometheus = {
        enable = true;
        source = {
            type = "share";
            name = "data";
            path = "/systems/sys-monitoring";
            ensureSource.enable = true;
        };
        destination = "/var/lib/prometheus-state";
        strategy.bindMapped = {
            enable = true;
            user = "prometheus";
            group = "prometheus";
            permissions = "0700";
        };
    };
    services.prometheus = {
        enable = true;
        stateDir = "prometheus-state";
        globalConfig.scrape_interval = cfg.scrapeInterval;
        scrapeConfigs = mapAttrsToList (sys-name: system: {
            job_name = "scrape-${sys-name}";
            static_configs =
                (mapAttrsToList (name: exporter: {
                    targets = [
                        "${config.lesbos.homelab.net.clients."${sys-name}".address}:${toString exporter.port}"
                    ];
                    labels = {
                        lsb-exporter = name;
                        lsb-system = sys-name;
                        lsb-address = config.lesbos.homelab.net.clients."${sys-name}".address;
                    };
                }) system.exporters)
                ++ (mapAttrsToList (name: exporter: {
                    targets = [
                        "${config.lesbos.homelab.net.clients."${sys-name}".address}:${toString exporter.port}"
                    ];
                    labels = {
                        lsb-exporter = name;
                        lsb-system = sys-name;
                        lsb-address = config.lesbos.homelab.net.clients."${sys-name}".address;
                    };
                }) system.custom-exporters)
                ++ [
                    {
                        targets = [
                            "${config.lesbos.homelab.net.clients."${sys-name}".address}:${toString system.node.port}"
                        ];
                        labels = {
                            lsb-exporter = "node";
                            lsb-system = sys-name;
                            lsb-address = config.lesbos.homelab.net.clients."${sys-name}".address;
                        };
                    }
                ];
        }) cfg.systems;
    };
}
