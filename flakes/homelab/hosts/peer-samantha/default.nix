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
                        authorizedKeys = [
                            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMtv697nzcNal/a/n87sy8rSqnFxRi9N0U61kKHyEc1z"
                            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJAdqW9W+ybE5OQkhUxllToVBMuGfurb5yQNxFaeoukd sambamfa@tundra"
                            "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC31Cl7SOYltE8vdbHs3XFFMvWc7RKoO9lhGZ7qS1OtO+pJ+u3dvzxoX0cpcd6GFA9tXilF/S/iRMa+CcXLaaGKelrSIPhcbne5od788KoEo6vHyhjs2KTSkIh12R2rj2LspPVwYwhsxCLCs6wsqFQk6a993ZUuU0D6py/75F1qatRAetsKXHhM4kxNUqou0Rrl9yN7LKwklRbLdxVeKv5dmMAEYpHHHACWVbCTqYN1fXDnQqfvHa/f56TGhfvsC8SK6AIlf0MN3dRqI6kleF2RGq0R+wSN231kxkS8YkACF/KyahU3mMeEvJKZ7R19vcsQqK79nscSlKb4eOZc5CmzPZHqBEDuemqshu1KEOBThG0eRT14ygIyk+DahXXUUJc1zX+O0FGCq0kmMygF5MvahmIW3qcCr/O/446iq9sEhoNhEfFUHAuURtV1SHxA+5jk3c4hhnlw9Qoqd6o28KvfkRlNO/jZy6znOjV49akbdpkWVJdiTRj2eEXeOSYOcuhiZAmAZlD5xx7gZtt+f84FqeDxCJ1Rp2L6AzZDJdQXI28txLUB6r80wWZ"
                        ];
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
        extraSetFlags = [
            "--advertise-exit-node"
            "--advertise-routes=192.168.64.0/24,192.168.0.0/24"
        ];
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
    services.openssh.settings.PasswordAuthentication = lib.mkForce true;
}
