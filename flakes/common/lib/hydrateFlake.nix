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
                                inputs.comin.nixosModules.comin
                                inputs.lesbos-common.nixosModules.default
                                ({config, pkgs, lib, self, inputs, system, ...}: {
                                    networking.hostName = key;
                                    system.stateVersion = hostConfig.stateVersion;
                                    lesbos.proxmox = self.nixosConfigurations."${key}".config.lesbos.proxmox;
                                    users.users.root = {
                                        password = "root";
                                    };
                                    services.comin = {
                                        enable = true;
                                        package = lib.mkForce inputs.comin.packages.${system}.default;
                                        repositorySubdir = "./flakes/${hostConfig.thisflake}";
                                        repositoryType = "flake";
                                        remotes = [
                                            {
                                                name = "origin";
                                                url = "https://github.com/dax-dot-gay/lesbos.nix.git";
                                                branches.main.name = "main";
                                            }
                                        ];
                                        hostname = key;
                                    };
                                    environment.etc = {
                                        "provisioning/ssh/ssh_host_ecdsa_key" = {
                                            mode = "0600";
                                            source = ../../${hostConfig.thisflake}/hosts/${hostname}/.host-secrets/etc/ssh/ssh_host_ecdsa_key;
                                            user = "root";
                                            group = "root";
                                        };
                                        "provisioning/ssh/ssh_host_ecdsa_key.pub" = {
                                            mode = "0600";
                                            source = ../../${hostConfig.thisflake}/hosts/${hostname}/.host-secrets/etc/ssh/ssh_host_ecdsa_key.pub;
                                            user = "root";
                                            group = "root";
                                        };
                                        "provisioning/ssh/ssh_host_ed25519_key" = {
                                            mode = "0600";
                                            source = ../../${hostConfig.thisflake}/hosts/${hostname}/.host-secrets/etc/ssh/ssh_host_ed25519_key;
                                            user = "root";
                                            group = "root";
                                        };
                                        "provisioning/ssh/ssh_host_ed25519_key.pub" = {
                                            mode = "0600";
                                            source = ../../${hostConfig.thisflake}/hosts/${hostname}/.host-secrets/etc/ssh/ssh_host_ed25519_key.pub;
                                            user = "root";
                                            group = "root";
                                        };
                                        "provisioning/ssh/ssh_host_rsa_key" = {
                                            mode = "0600";
                                            source = ../../${hostConfig.thisflake}/hosts/${hostname}/.host-secrets/etc/ssh/ssh_host_rsa_key;
                                            user = "root";
                                            group = "root";
                                        };
                                        "provisioning/ssh/ssh_host_rsa_key.pub" = {
                                            mode = "0600";
                                            source = ../../${hostConfig.thisflake}/hosts/${hostname}/.host-secrets/etc/ssh/ssh_host_rsa_key.pub;
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
                                        setupSecretsForUsers.deps = [ "provisionHostKeys" ];
                                        setupSecrets.deps = [ "provisionHostKeys" ];
                                    };
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
                            defaultSopsFile = ../../secrets/global.yaml;
                            age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
                        };
                    }
                    (optionalAttrs enable_root {
                        sops.secrets."users/root/password" = {
                            sopsFile = ../../secrets/${thisflake}/per-system/${hostname}/system.yaml;
                            neededForUsers = true;
                        };
                        sops.secrets."ssh/root_key" = {
                            sopsFile = ../../secrets/${thisflake}/global.yaml;
                            mode = "0400";
                        };
                        users.users.root = {
                            hashedPasswordFile = config.sops.secrets."users/root/password".path;
                            openssh.authorizedKeys.keyFiles = [
                                config.sops.secrets."ssh/root_key".path
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
                            sopsFile = ../../secrets/${thisflake}/per-system/${hostname}/system.yaml;
                            neededForUsers = true;
                        };
                        sops.secrets."ssh/user_key" = {
                            sopsFile = ../../secrets/${thisflake}/global.yaml;
                            mode = "0444";
                        };
                        users.users.${username} = {
                            extraGroups = if enable_user_wheel then [ "wheel" ] else [ ];
                            hashedPasswordFile = config.sops.secrets."users/${username}/password".path;
                            openssh.authorizedKeys.keyFiles = [
                                config.sops.secrets."ssh/user_key".path
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
