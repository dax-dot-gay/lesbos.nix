{ config, lib, ... }:
with lib;
let
    net = config.lesbos.homelab.net;
    wan_iface = config.lesbos.proxmox.network.interface_names.net0;
    lan_iface = config.lesbos.proxmox.network.interface_names.net1;
    getLanAddress =
        suffix:
        let
            addr_split = splitString "." net.lan.gateway;
            addr_head = "${elemAt addr_split 0}.${elemAt addr_split 1}.${elemAt addr_split 2}.";
        in
        "${addr_head}${toString suffix}";
    allForwards = flatten (
        mapAttrsToList (
            _: client:
            map (forward: {
                tcp = (forward.protocol == "tcp") || (forward.protocol == "both");
                udp = (forward.protocol == "udp") || (forward.protocol == "both");
                ports =
                    if isInt forward.externalPort then
                        [ forward.externalPort ]
                    else
                        (range forward.externalPort.from forward.externalPort.to);
            }) client.forward_ports
        ) net.clients
    );
    tcpForwards = flatten (map (forward: forward.ports) (filter (forward: forward.tcp) allForwards));
    udpForwards = flatten (map (forward: forward.ports) (filter (forward: forward.udp) allForwards));
    dnsmap = listToAttrs (flatten (mapAttrsToList (key: value: nameValuePair key value.dns) net.clients));
in
{
    networking.hostName = mkForce net.wan.hostname;
    networking.defaultGateway = mkForce {
        address = net.wan.gateway;
        interface = wan_iface;
    };
    nixos-utilities.systems.router = {
        enable = true;
        config = {
            domain = net.lan.domain;
            nameservers = [
                "1.1.1.1"
                net.lan.gateway
            ];
            wan = {
                type = "static";
                interface = wan_iface;
                static = {
                    ipv4 = {
                        address = net.wan.address;
                        prefixLength = net.wan.prefix_length;
                        gateway = net.wan.gateway;
                    };
                    dnsServers = [
                        "1.1.1.1"
                        net.lan.gateway
                    ];
                };
            };
            lan = {
                isolation.enable = true;
                networks.lan = {
                    name = "lan";
                    ipv4 = {
                        gateway = net.lan.gateway;
                        subnet = net.lan.subnet;
                        prefixLength = net.lan.prefix_length;
                    };
                    bridge = {
                        name = "br0";
                        interfaces = [ lan_iface ];
                    };
                    dhcp = {
                        enable = true;
                        start = getLanAddress 100;
                        end = getLanAddress 200;
                        dynamicDomain = net.lan.domain;
                    };
                    dns = {
                        enable = true;
                        forwardUnlisted = true;
                        records.a_records = mapAttrs' (host: client: {
                            name = client.dns;
                            value = {
                                target = client.address;
                                comment = "${client.dns} -> ${client.address} (${host})";
                            };
                        }) (filterAttrs (_: client: isString client.dns) net.clients);
                    };
                };
                primaryNetwork = "lan";
            };
            portForwarding = concatLists (
                mapAttrsToList (
                    host: client:
                    (map (forward: {
                        protocol = forward.protocol;
                        externalPort = forward.externalPort;
                        internalPort = forward.internalPort;
                        destinationIp = client.address;
                    }) client.forward_ports)
                ) net.clients
            );
            dns = {
                enable = true;
                upstreamServers = [
                    "1.1.1.1"
                ];
            };
            firewall = {
                allowPing = true;
                allowedTCPPorts = tcpForwards;
                allowedUDPPorts = udpForwards;
            };
            nat = {
                enable = true;
            };
        };
    };
}
