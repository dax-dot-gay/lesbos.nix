{
    description = "Flake containing configs for my homelab";
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
        sops-nix = {
            url = "github:Mic92/sops-nix";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        comin = {
            url = "github:nlewo/comin";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        disko = {
            url = "github:nix-community/disko/latest";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        nixos-utilities = {
            url = "github:dax-dot-gay/nixos-utilities";
            inputs.nixpkgs.follows = "nixpkgs";
            inputs.sops-nix.follows = "sops-nix";
            inputs.comin.follows = "comin";
        };
    };

    outputs =
        { self, ... }@inputs: let
            hydrateFlake = (import ./common/lib).flake.hydrate;
        in
        hydrateFlake
            {
                inherit self inputs;
                system = "x86_64-linux";
                extraOverlays = [ ];
            }
            (
                {
                    self,
                    pkgs,
                    system,
                    ...
                }@inputs:
                {
                    proxmoxConfigurations = {
                        lsb-sys-router = {
                            id = 500;
                            path = ./hosts/lsb-sys-router;
                            flake = "homelab";
                            name = "lsb-sys-router";
                            tags = [
                                # Add tags here
                            ];
                            modules = [
                                # Add extra modules here
                            ];
                            extraSpecialArgs = {
                                # Add extra specialArgs here
                            };
                        };
                        # @add:host:proxmox
                    };
                }
            );
}
