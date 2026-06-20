{ config, lib, ... }:
with lib;
let
    portSpecType = types.either types.port (
        types.submodule {
            options = {
                from = mkOption {
                    type = types.port;
                    description = "Starting port in the range.";
                };
                to = mkOption {
                    type = types.port;
                    description = "Ending port in the range.";
                };
            };
        }
    );
    portForwardRequest = types.submodule {
        options = {
            protocol = mkOption {
                description = "Which protocol to forward";
                type = types.enum [
                    "both"
                    "tcp"
                    "udp"
                ];
                default = "both";
            };
            externalPort = mkOption {
                description = "External port (or range) to forward from";
                type = portSpecType;
            };
            internalPort = mkOption {
                description = "Internal port (or range) to forward to. Defaults to `externalPort` if null";
                type = types.nullOr portSpecType;
                default = null;
            };
        };
    };
    clientType = types.submodule (
        { config, ... }:
        {
            options = {
                hostname = mkOption {
                    description = "Hostname of this client (defaults to this set's key)";
                    type = types.str;
                    default = config._module.args.name;
                };
                description = mkOption {
                    description = "Description of this client";
                    type = types.str;
                    default = "";
                };
                address = mkOption {
                    description = "Desired IP address (should be within the primary network's subnet!!!)";
                    type = types.singleLineStr;
                };
                dns = mkOption {
                    description = "DNS names to set internally";
                    type = types.listOf types.str;
                    default = [];
                    example = ["host.lan"];
                };
                forward_ports = mkOption {
                    description = "List of ports to forward from this host";
                    type = types.listOf portForwardRequest;
                    default = [ ];
                };
            };
        }
    );
in
{
    options = {
        lesbos.homelab.net = {
            wan = {
                hostname = mkOption {
                    description = "Hostname to present to the external network";
                    type = types.str;
                    default = config.lesbos.proxmox.metadata.name;
                };
                address = mkOption {
                    type = types.str;
                    description = "Static IPv4 address assigned to the WAN interface.";
                };
                prefix_length = mkOption {
                    type = types.int;
                    default = 24;
                    description = "Prefix length for the static IPv4 network.";
                };
                gateway = mkOption {
                    type = types.str;
                    description = "Default IPv4 gateway for static mode.";
                };
            };
            lan = {
                domain = mkOption {
                    description = "Domain for local dynamic DNS";
                    type = types.singleLineStr;
                };
                gateway = mkOption {
                    description = "IPv4 LAN gateway";
                    type = types.singleLineStr;
                };
                prefix_length = mkOption {
                    description = "Subnet prefix length";
                    type = types.ints.positive;
                    default = 24;
                };
                subnet = mkOption {
                    description = "Subnet specifier";
                    type = types.singleLineStr;
                };
            };
            clients = mkOption {
                description = ''
                    Clients explicitly defined as members of this network.
                    This configures both the router itself and the individual clients.
                '';
                type = types.attrsOf clientType;
            };
        };
    };
}
