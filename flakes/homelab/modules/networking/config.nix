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
        port_spec = port_spec;
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
                allowedTCPPorts = [ map (f: f.port_spec) (filter (forward: forward.has_tcp && forward.is_single_port) forwards) ];
                allowedUDPPorts = [ map (f: f.port_spec) (filter (forward: forward.has_udp && forward.is_single_port) forwards) ];
                allowedTCPPortRanges = [ map (f: f.port_spec) (filter (forward: forward.has_tcp && forward.is_port_range) forwards) ];
                allowedUDPPortRanges = [ map (f: f.port_spec) (filter (forward: forward.has_udp && forward.is_port_range) forwards) ];
            };
            useDHCP = false;
        };
    };
}
