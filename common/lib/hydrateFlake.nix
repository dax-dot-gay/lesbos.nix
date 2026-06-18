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
                    flake ? "homelab",
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
                                ../modules
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
