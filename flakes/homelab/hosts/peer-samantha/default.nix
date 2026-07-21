{
    config,
    lib,
    pkgs,
    inputs,
    ...
}:
{
    imports = [ ./provision-secrets.nix ];
    lesbos = {
        info = {
            canonicalName = "peer-samantha";
            flake = "homelab";
            stateVersion = "26.05";
            runningVersion = "26.05";
        };
        proxmox = {
            enable = true;
            resources = {
                cores = 4;
                memory = 8192;
            };
            storage = {
                disk_size = "64G";
                virtiofs = [
                    {
                        name = "data";
                        mount = true;
                        id = "DATA";
                        expose_acl = true;
                        expose_xattr = true;
                    }
                ];
            };
            network.primary.bridge = "vmbr3";
            start.order = 100;
        };
        base.users = {
            root = {
                enable = true;
                ssh.enable = true;
                password = {
                    enable = true;
                    hash = "$y$j9T$dqtofzM7Pl4lzYzznBLm/.$rNvcWH.F7dqaStRwLRRrw9l32ZgC1F9k6M.t7CdxCz8";
                };
            };
            users = {
                samantha = {
                    enable = true;
                    ssh = {
                        enable = true;
                        authorizedKeys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMtv697nzcNal/a/n87sy8rSqnFxRi9N0U61kKHyEc1z"];
                    };
                    password = {
                        enable = true;
                        hash = "$y$j9T$7IY5ppGGRfesUXTmqHsQ.1$HqBSWUc1Ykla97b7gs/BeKMXo9FRrKW2fu99r99vpa3";
                    };
                };
            };
        };
        volumes.samantha = {
            enable = true;
            source = {
                type = "share";
                name = "data";
                path = "/data/users/samantha";
                ensureSource = {
                    enable = true;
                    user = "root";
                    group = "root";
                    mode = "0770";
                };
            };
            destination = "/home/samantha/shared";
            strategy.bindMapped = {
                enable = true;
                user = "samantha";
                permissions = "0700";
            };
        };
    };
    services.tailscale = {
        enable = true;
        extraSetFlags = [ "--advertise-exit-node" "--advertise-routes=192.168.64.0/24,192.168.0.0/24" ];
        useRoutingFeatures = "server";
    };
    networking.nftables.enable = true;
    networking.firewall = {
        enable = true;
        # Always allow traffic from your Tailscale network
        trustedInterfaces = [ config.services.tailscale.interfaceName ];
        # Allow the Tailscale UDP port through the firewall
        allowedUDPPorts = [ config.services.tailscale.port ];
    };

    # 2. Force tailscaled to use nftables (Critical for clean nftables-only systems)
    # This avoids the "iptables-compat" translation layer issues.
    systemd.services.tailscaled.serviceConfig.Environment = [
        "TS_DEBUG_FIREWALL_MODE=nftables"
    ];

    # 3. Optimization: Prevent systemd from waiting for network online
    # (Optional but recommended for faster boot with VPNs)
    systemd.network.wait-online.enable = false;
    boot.initrd.systemd.network.wait-online.enable = false;
}
