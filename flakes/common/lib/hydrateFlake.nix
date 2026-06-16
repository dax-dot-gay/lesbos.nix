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
in
(
    resolved
    // (
        with lib;
        let
            processProxmoxConfiguration =
                key:
                {
                    id,
                    name ? key,
                    tags ? [ ],
                    path ? ./hosts/${key},
                    modules ? [ ],
                    extraSpecialArgs ? { },
                }:
                {
                    nixosConfigurations.${key} = inputs.nixpkgs.lib.nixosSystem {
                        inherit system;
                        specialArgs = {
                            inherit inputs system;
                        } // extraSpecialArgs;
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
                        ] ++ modules;
                    };
                    packages.${system}."host-${key}" = self.nixosConfigurations."${key}".config.system.build.VMA;
                    packages.${system}."host-${key}-deploy" = self.nixosConfigurations."${key}".config.lesbos.proxmox.__deploy_script;
                    packages.${system}."host-${key}-setup" = self.nixosConfigurations."${key}".config.lesbos.proxmox.__setup_script;
                };
        in
        mkMerge [
            (mkMerge (mapAttrsToList (key: config: processProxmoxConfiguration key config) (resolved.proxmoxConfigurations or {})))
        ]
    )
)
