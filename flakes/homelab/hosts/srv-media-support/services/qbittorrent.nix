{
    config,
    pkgs,
    lib,
    ...
}:
with lib;
{
    lesbos.secrets.system = {
        "wg.conf" = {
            mode = "0400";
        };
    };

    # Declarative qbittorrent config
    services.qbittorrent = {
        enable = true;
        declarative = true;
        authFile = config.sops.secrets."qbittorrent/authfile".path;
        user = "qbittorrent";
        group = "qbittorrent";
        web = {
            enable = true;
            port = 8112;
            openFirewall = true;
        };
        dataDir = "/media-support/services/qbittorrent";
        config = {
            daemon_port = 58846;
            allow_remote = true;
            download_location = "/media-support/downloads/in-progress";
            torrentfiles_location = "/media-support/downloads/torrents";
            max_upload_slots_global = 6;
            enabled_plugins = [
                "Label"
                "Stats"
            ];
            max_active_downloading = 6;
            max_active_limit = 8;
            max_active_seeding = 5;
            move_completed = true;
            move_completed_path = "/media-support/downloads/completed";
            seed_time_limit = 180;
            seed_time_ratio_limit = 7.0;
            remove_seed_at_ratio = true;
            add_paused = false;
        };
    };

    # qbittorrent VPN
    systemd.services."netns@" = {
        description = "%I network namespace";
        before = [ "network.target" ];
        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${pkgs.iproute2}/bin/ip netns add %I";
            ExecStop = "${pkgs.iproute2}/bin/ip netns del %I";
        };
    };

    # setting up wireguard interface within network namespace
    systemd.services.wg = {
        description = "wg network interface";
        bindsTo = [ "netns@wg.service" ];
        requires = [ "network-online.target" ];
        after = [ "netns@wg.service" ];
        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart =
                with pkgs;
                writers.writeBash "wg-up" ''
                    set -e
                    ${iproute2}/bin/ip link add wg0 type wireguard
                    ${iproute2}/bin/ip link set wg0 netns wg
                    ${iproute2}/bin/ip -n wg address add ${config.lesbos.homelab.net.clients.srv-media-support.address}/${toString config.lesbos.homelab.net.lan.prefix_length} dev wg0
                    # ${iproute2}/bin/ip -n wg -6 address add <ipv6 VPN addr/cidr> dev wg0
                    ${iproute2}/bin/ip netns exec wg \
                      ${wireguard-tools}/bin/wg setconf wg0 ${config.sops.secrets."wg.conf".path}
                    ${iproute2}/bin/ip -n wg link set wg0 up
                    # need to set lo up as network namespace is started with lo down
                    ${iproute2}/bin/ip -n wg link set lo up
                    ${iproute2}/bin/ip -n wg route add default dev wg0
                    # ${iproute2}/bin/ip -n wg -6 route add default dev wg0
                '';
            ExecStop =
                with pkgs;
                writers.writeBash "wg-down" ''
                    ${iproute2}/bin/ip -n wg route del default dev wg0
                    # ${iproute2}/bin/ip -n wg -6 route del default dev wg0
                    ${iproute2}/bin/ip -n wg link del wg0
                '';
        };
    };

    # binding qbittorrent to network namespace
    systemd.services.qbittorrent.bindsTo = [ "netns@wg.service" ];
    systemd.services.qbittorrent.requires = [
        "network-online.target"
        "wg.service"
    ];
    systemd.services.qbittorrent.serviceConfig.NetworkNamespacePath = [ "/var/run/netns/wg" ];

    # allowing qbittorrentweb to access qbittorrent in network namespace, a socket is necesarry
    systemd.sockets."proxy-to-qbittorrent" = {
        enable = true;
        description = "Socket for Proxy to qbittorrent Daemon";
        listenStreams = [ "58846" ];
        wantedBy = [ "sockets.target" ];
    };

    # creating proxy service on socket, which forwards the same port from the root namespace to the isolated namespace
    systemd.services."proxy-to-qbittorrent" = {
        enable = true;
        description = "Proxy to qbittorrent Daemon in Network Namespace";
        requires = [
            "qbittorrent.service"
            "proxy-to-qbittorrent.socket"
        ];
        after = [
            "qbittorrent.service"
            "proxy-to-qbittorrent.socket"
        ];
        unitConfig = {
            JoinsNamespaceOf = "qbittorrent.service";
        };
        serviceConfig = {
            User = "qbittorrent";
            Group = "qbittorrent";
            ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd --exit-idle-time=5min 127.0.0.1:58846";
            PrivateNetwork = "yes";
        };
    };
}
