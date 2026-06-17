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
                    };
                    packages.${system} = {
                        "host-${key}" = self.nixosConfigurations."${key}".config.system.build.VMA;
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
                    root_passhash ? "",
                    enable_user,
                    stateVersion,
                    enable_user_wheel ? false,
                    username ? "",
                    user_passhash ? ""
                }:
                recursiveUpdateAttrs [
                    {
                        networking.hostName = hostname;
                        system.stateVersion = stateVersion;
                    }
                    (optionalAttrs enable_root {
                        assertions = [
                            {
                                assertion = (length root_passhash) > 0;
                                message = "Root password hash must be set!";
                            }
                        ];
                        users.users.root = {
                            hashedPassword = root_passhash;
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
                            {
                                assertion = (length user_passhash) > 0;
                                message = "User password hash must be set!";
                            }
                        ];
                        users.users.${username} = {
                            extraGroups = if enable_user_wheel then [ "wheel" ] else [ ];
                            hashedPassword = user_passhash;
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
