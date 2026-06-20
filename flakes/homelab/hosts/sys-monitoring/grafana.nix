{ config, ... }:
{
    lesbos.secrets.system = {
        "grafana/username" = {
            owner = "grafana";
            group = "grafana";
            mode = "0400";
        };
        "grafana/password" = {
            owner = "grafana";
            group = "grafana";
            mode = "0400";
        };
        "grafana/email" = {
            owner = "grafana";
            group = "grafana";
            mode = "0400";
        };
    };
    lesbos.volumes.grafana = {
        enable = true;
        source = {
            type = "share";
            name = "data";
            path = "/systems/sys-monitoring/grafana/";
            ensureSource = true;
        };
        destination = "/var/lib/grafana";
        strategy.bindMapped = {
            enable = true;
            user = "grafana";
            group = "grafana";
            permissions = "0700";
        };
        required_by = [ "grafana.service" ];
    };
    services.grafana = {
        enable = true;
        openFirewall = true;
        dataDir = "/var/lib/grafana";
        settings = {
            database = {
                type = "sqlite3";
            };
            server = {
                http_addr = "0.0.0.0";
                http_port = 8999;
                enforce_domain = true;
                enable_gzip = true;
                domain = "grafana.dax.gay";
            };
            security = {
                admin_email = "$__file{${config.sops.secrets."grafana/email".path}}";
                admin_user = "$__file{${config.sops.secrets."grafana/username".path}}";
                admin_password = "$__file{${config.sops.secrets."grafana/password".path}}";
            };
            analytics.reporting_enabled = false;
        };
        provision = {
            enable = true;
            datasources.settings.datasources = [
                {
                    name = "Prometheus";
                    type = "prometheus";
                    url = "http://${config.services.prometheus.listenAddress}:${toString config.services.prometheus.port}";
                    isDefault = true;
                    editable = false;
                }
            ];
        };
    };
}
