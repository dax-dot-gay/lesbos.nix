{ config, lib, ... }:
with lib;
let
    cfg = config.lesbos.monitoring;
    system =
        if (hasAttr config.lesbos.info.canonicalName cfg.systems) then
            cfg.systems."${config.lesbos.info.canonicalName}"
        else
            null;
    resolveCollectors = collectors: {
        enabledCollectors = map (collector: replaceString "+" "" collector) (
            filter (collector: hasPrefix "+" collector) collectors
        );
        disabledCollectors = map (collector: replaceString "-" "" collector) (
            filter (collector: hasPrefix "-" collector) collectors
        );
    };
in
{
    config = mkIf (!(isNull system)) {
        services.prometheus.exporters = {
            node = {
                enable = true;
                port = system.node.port;
            }
            // (resolveCollectors system.node.collectors);
        }
        // (mapAttrs (
            name: exporter:
            {
                enable = true;
                port = exporter.port;
                user = exporter.user;
                group = exporter.group;
                extraFlags = exporter.extraFlags;
            }
            // exporter.extraConfig
        ) system.exporters);
        services.comin.exporter = mkIf system.comin.enable {
            listen_address = "0.0.0.0";
            port = system.comin.port;
        };
        networking.firewall.allowedTCPPorts = [
            system.node.port
        ]
        ++ (mapAttrsToList (_: v: v.port) system.exporters)
        ++ (mapAttrsToList (_: v: v.port) system.custom-exporters)
        ++ (optional system.comin.enable system.comin.port);
    };
}
