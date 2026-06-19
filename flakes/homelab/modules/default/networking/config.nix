{ config, lib, ... }:
with lib;
let
    cfg = config.lesbos.homelab.net;
    this = cfg.clients."${config.lesbos.proxmox.metadata.name}";
    iface = config.lesbos.proxmox.network.interface_names.net0;
    parsePortForward = {protocol, externalPort, internalPort}: let
        port_spec = if (isNull internalPort) then externalPort else internalPort;
    in {
        has_tcp = (protocol == "tcp") || (protocol == "both");
        has_udp = (protocol == "udp") || (protocol == "both");
        single_port = if (typeOf port_spec) == "int" then (toInt port_spec) else 0;
        range_port = if (typeOf port_spec) == "set" then port_spec else {from = 0; to = 0;};
        is_single_port = (typeOf port_spec) == "int";
        is_port_range = (typeOf port_spec) == "set";
    };

    forwards = map parsePortForward this.forward_ports;
in
{
    config = mkIf (!config.nixos-utilities.systems.router.enable) {
        networking = {
            hostName = mkForce this.hostname;
            interfaces."${iface}" = {
                ipv4.addresses = [{
                    address = this.address;
                    prefixLength = cfg.lan.prefix_length;
                }];
            };
            defaultGateway = {
                address = cfg.lan.gateway;
                interface = iface;
            };
            firewall = {
                enable = true;
                allowPing = true;
                allowedTCPPorts = map (f: f.single_port) (filter (forward: forward.has_tcp && forward.is_single_port) forwards);
                allowedUDPPorts = map (f: f.single_port) (filter (forward: forward.has_udp && forward.is_single_port) forwards);
                allowedTCPPortRanges = map (f: f.range_port) (filter (forward: forward.has_tcp && forward.is_port_range) forwards);
                allowedUDPPortRanges = map (f: f.range_port) (filter (forward: forward.has_udp && forward.is_port_range) forwards);
            };
            useDHCP = false;
        };
    };
}
