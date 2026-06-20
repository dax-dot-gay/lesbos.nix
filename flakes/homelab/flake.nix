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
        lesbos-common = {
            url = "github:dax-dot-gay/lesbos.nix?dir=flakes/common"; # Can't reference locally because nixd >:(
            inputs.nixpkgs.follows = "nixpkgs";
            inputs.sops-nix.follows = "sops-nix";
            inputs.comin.follows = "comin";
            inputs.nixos-utilities.follows = "nixos-utilities";
        };
    };

    outputs =
        { self, lesbos-common, ... }@inputs:
        lesbos-common.lib.hydrateFlake
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
                            inherit self;
                            id = 500;
                            path = ./hosts/lsb-sys-router;
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
                        sys-storage = {
                            inherit self;
                            id = 501;
                            path = ./hosts/sys-storage;
                            name = "sys-storage";
                            tags = [
                                # Add tags here
                            ];
                            modules = [
                                ./modules/volumes
                                # Add extra modules here
                            ];
                            extraSpecialArgs = {
                                # Add extra specialArgs here
                            };
                        };
                        sys-ingress = {
                            inherit self;
                            id = 502;
                            path = ./hosts/sys-ingress;
                            name = "sys-ingress";
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
                        srv-matrix = {
                            inherit self;
                            id = 510;
                            path = ./hosts/srv-matrix;
                            name = "srv-matrix";
                            tags = [
                                # Add tags here
                            ];
                            modules = [
                                ./modules/volumes
                                # Add extra modules here
                            ];
                            extraSpecialArgs = {
                                # Add extra specialArgs here
                            };
                        };
                        sys-monitoring = {
                            inherit self;
                            id = 503;
                            path = ./hosts/sys-monitoring;
                            name = "sys-monitoring";
                            tags = [
                                # Add tags here
                            ];
                            modules = [
                                ./modules/volumes
                                # Add extra modules here
                            ];
                            extraSpecialArgs = {
                                # Add extra specialArgs here
                            };
                        };
                        srv-gameservers = {
                            inherit self;
                            id = 511;
                            path = ./hosts/srv-gameservers;
                            name = "srv-gameservers";
                            tags = [
                                # Add tags here
                            ];
                            modules = [
                                ./modules/volumes
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
