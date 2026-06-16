{
    self,
    system,
    inputs,
    extraOverlays ? [ ],
}:
outputs:
let
    inherit system inputs;
    pkgs = import inputs.nixpkgs {
        inherit system;
        config = {
            allowUnfree = true;
        };
        overlays = [
            # Global overlays
        ]
        ++ extraOverlays;
    };

    lib = pkgs.lib;

    resolved = outputs (
        inputs
        // {
            inherit self system pkgs;
        }
    );

    toRemove = [
        "proxmoxConfigurations"
    ];

    checkToRemove = name: _: !(lib.any (x: x == name) toRemove);

    recursiveUpdateAttrs =
        attrs:
        (
            if (lib.length attrs) == 0 then
                [ ]
            else if (lib.length attrs) == 0 then
                lib.head attrs
            else
                (lib.foldl (accumulator: current: lib.recursiveUpdate accumulator current) (lib.head attrs) (
                    lib.tail attrs
                ))
        );
in
lib.filterAttrs checkToRemove (
    resolved
    // (
        with lib;
        let
            processProxmoxConfiguration =
                key:
                {
                    id,
                    path,
                    hostConfig,
                    name ? key,
                    tags ? [ ],
                    modules ? [ ],
                    extraSpecialArgs ? { },
                }:
                {
                    nixosConfigurations = {
                        "${key}" = inputs.nixpkgs.lib.nixosSystem {
                            inherit system;
                            specialArgs = {
                                inherit inputs system;
                            }
                            // extraSpecialArgs;
                            modules = [
                                "${inputs.nixpkgs}/nixos/modules/virtualisation/proxmox-image.nix"
                                inputs.sops-nix.nixosModules.sops
                                inputs.comin.nixosModules.comin
                                inputs.nixos-utilities.nixosModules.default
                                inputs.lesbos-common.nixosModules.default
                                path
                                {
                                    lesbos.proxmox = {
                                        enable = mkForce true;
                                        metadata = {
                                            id = mkDefault id;
                                            name = mkDefault name;
                                            tags = mkDefault tags;
                                        };
                                    };
                                }
                                (
                                    {
                                        pkgs,
                                        config,
                                        lib,
                                        ...
                                    }:
                                    (processHostConfiguration config hostConfig)
                                )
                            ]
                            ++ modules;
                        };
                        "${key}-initializer" = inputs.nixpkgs.lib.nixosSystem {
                            inherit system;
                            specialArgs = {
                                inherit inputs system self;
                            };
                            modules = [
                                "${inputs.nixpkgs}/nixos/modules/virtualisation/proxmox-image.nix"
                                inputs.lesbos-common.nixosModules.default
                                ({lib, self, inputs, system, ...}: {
                                    networking.hostName = key;
                                    system.stateVersion = hostConfig.stateVersion;
                                    lesbos.proxmox = self.nixosConfigurations."${key}".config.lesbos.proxmox;
                                    users.users.root = {
                                        password = "root";
                                    };
                                    environment.etc = {
                                        "provisioning/ssh/ssh_host_ecdsa_key" = {
                                            mode = "0600";
                                            source = ../../${hostConfig.thisflake}/hosts/${hostConfig.hostname}/.host-secrets/etc/ssh/ssh_host_ecdsa_key;
                                            user = "root";
                                            group = "root";
                                        };
                                        "provisioning/ssh/ssh_host_ecdsa_key.pub" = {
                                            mode = "0600";
                                            source = ../../${hostConfig.thisflake}/hosts/${hostConfig.hostname}/.host-secrets/etc/ssh/ssh_host_ecdsa_key.pub;
                                            user = "root";
                                            group = "root";
                                        };
                                        "provisioning/ssh/ssh_host_ed25519_key" = {
                                            mode = "0600";
                                            source = ../../${hostConfig.thisflake}/hosts/${hostConfig.hostname}/.host-secrets/etc/ssh/ssh_host_ed25519_key;
                                            user = "root";
                                            group = "root";
                                        };
                                        "provisioning/ssh/ssh_host_ed25519_key.pub" = {
                                            mode = "0600";
                                            source = ../../${hostConfig.thisflake}/hosts/${hostConfig.hostname}/.host-secrets/etc/ssh/ssh_host_ed25519_key.pub;
                                            user = "root";
                                            group = "root";
                                        };
                                        "provisioning/ssh/ssh_host_rsa_key" = {
                                            mode = "0600";
                                            source = ../../${hostConfig.thisflake}/hosts/${hostConfig.hostname}/.host-secrets/etc/ssh/ssh_host_rsa_key;
                                            user = "root";
                                            group = "root";
                                        };
                                        "provisioning/ssh/ssh_host_rsa_key.pub" = {
                                            mode = "0600";
                                            source = ../../${hostConfig.thisflake}/hosts/${hostConfig.hostname}/.host-secrets/etc/ssh/ssh_host_rsa_key.pub;
                                            user = "root";
                                            group = "root";
                                        };
                                    };
                                    system.activationScripts = {
                                        provisionHostKeys = {
                                            # Run after /dev has been mounted
                                            deps = [ "specialfs" ];
                                            text = ''
                                                cp /etc/provisioning/ssh/* /etc/ssh/
                                            '';
                                        };
                                    };
                                    systemd.services.rebuild_actual = {
                                        wantedBy = ["multi-user.target"];
                                        wants = ["systemd-networkd-wait-online.service"];
                                        serviceConfig = {
                                            User = "root";
                                            Group = "root";
                                            Type = "oneshot";
                                        };
                                        script = ''
                                            nixos-rebuild --flake "github:dax-dot-gay/lesbos.nix?dir=flakes/${hostConfig.thisflake}#${key}" --refresh switch
                                        '';
                                        path = ["/run/current-system/sw"];
                                    };
                                    systemd.network.wait-online.enable = true;
                                })
                            ];
                        };
                    };
                    packages.${system} = {
                        "host-${key}" = self.nixosConfigurations."${key}-initializer".config.system.build.VMA;
                        "host-${key}-deploy" = self.nixosConfigurations."${key}".config.lesbos.proxmox.__deploy_script;
                        "host-${key}-setup" = self.nixosConfigurations."${key}".config.lesbos.proxmox.__setup_script;
                    };
                };

            processHostConfiguration =
                config:
                {
                    thisflake,
                    hostname,
                    enable_root,
                    enable_user,
                    stateVersion,
                    enable_user_wheel ? false,
                    username ? "",
                }:
                recursiveUpdateAttrs [
                    {
                        networking.hostName = hostname;
                        system.stateVersion = stateVersion;
                        sops = {
                            defaultSopsFile = ../../../secrets/global.yaml;
                            age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
                        };
                    }
                    (optionalAttrs enable_root {
                        sops.secrets."users/root/password" = {
                            sopsFile = ../../../secrets/${thisflake}/per-system/${hostname}/system.yaml;
                            neededForUsers = true;
                        };
                        users.users.root = {
                            hashedPasswordFile = config.sops.secrets."users/root/password".path;
                            openssh.authorizedKeys.keys = [
                                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKFsoY66q/ej1AfjYuJ1d2t7RWdKizRi2TCJ73vEP0iq root@lesbos.peer"
                            ];
                        };
                    })
                    (optionalAttrs enable_user {
                        assertions = [
                            {
                                assertion = (length username) > 0;
                                message = "Username must be set!";
                            }
                        ];
                        sops.secrets."users/${username}/password" = {
                            sopsFile = ../../../secrets/${thisflake}/per-system/${hostname}/system.yaml;
                            neededForUsers = true;
                        };
                        users.users.${username} = {
                            extraGroups = if enable_user_wheel then [ "wheel" ] else [ ];
                            hashedPasswordFile = config.sops.secrets."users/${username}/password".path;
                            openssh.authorizedKeys.keys = [
                                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKFsoY66q/ej1AfjYuJ1d2t7RWdKizRi2TCJ73vEP0iq root@lesbos.peer"
                            ];
                        };
                    })
                ];
        in
        recursiveUpdateAttrs [
            (recursiveUpdateAttrs (
                mapAttrsToList (key: config: processProxmoxConfiguration key config) (
                    resolved.proxmoxConfigurations or { }
                )
            ))
        ]
    )
)
