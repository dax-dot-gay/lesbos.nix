{
    description = "Flake containing configs for my homelab";
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
        nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
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
        jellarr = {
            url = "github:venkyr77/jellarr";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs =
        { self, lesbos-common, nixpkgs-unstable, ... }@inputs:
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
                                "lesbos.nix"
                                "infrastructure"
                                "critical"
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
                                "lesbos.nix"
                                "infrastructure"
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
                                "lesbos.nix"
                                "infrastructure"
                                "critical"
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
                                "lesbos.nix"
                                "services"
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
                                "lesbos.nix"
                                "infrastructure"
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
                                "lesbos.nix"
                                "services"
                            ];
                            modules = [
                                ./modules/volumes
                                # Add extra modules here
                            ];
                            extraSpecialArgs = {
                                # Add extra specialArgs here
                            };
                        };
                        srv-jellyfin = {
                            inherit self;
                            id = 512;
                            path = ./hosts/srv-jellyfin;
                            name = "srv-jellyfin";
                            tags = [
                                "lesbos.nix"
                                "services"
                                "media"
                            ];
                            modules = [
                                ./modules/volumes
                                inputs.jellarr.nixosModules.default
                                # Add extra modules here
                            ];
                            extraSpecialArgs = {
                                # Add extra specialArgs here
                            };
                        };
                        srv-media-support = {
                            inherit self;
                            id = 513;
                            path = ./hosts/srv-media-support;
                            name = "srv-media-support";
                            tags = [
                                "lesbos.nix"
                                "services"
                                "media"
                            ];
                            modules = [
                                ./modules/volumes
                                # Add extra modules here
                            ];
                            extraSpecialArgs = {
                                # Add extra specialArgs here
                            };
                        };
                        sys-datastore = {
                            inherit self;
                            id = 504;
                            path = ./hosts/sys-datastore;
                            name = "sys-datastore";
                            tags = [
                                "lesbos.nix"
                                "infrastructure"
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
                        sys-auth = {
                            inherit self;
                            id = 505;
                            path = ./hosts/sys-auth;
                            name = "sys-auth";
                            tags = [
                                "lesbos.nix"
                                "infrastructure"
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
                        srv-books = {
                            inherit self;
                            id = 514;
                            path = ./hosts/srv-books;
                            name = "srv-books";
                            tags = [
                                "lesbos.nix"
                                "services"
                                "media"
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
                        sys-cicd = {
                            inherit self;
                            id = 506;
                            path = ./hosts/sys-cicd;
                            name = "sys-cicd";
                            tags = [
                                "lesbos.nix"
                                "infrastructure"
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
                        srv-ttrpg = {
                            inherit self;
                            id = 515;
                            path = ./hosts/srv-ttrpg;
                            name = "srv-ttrpg";
                            tags = [
                                "lesbos.nix"
                                "services"
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
                        srv-misc = {
                            inherit self;
                            id = 516;
                            path = ./hosts/srv-misc;
                            name = "srv-misc";
                            tags = [
                                "lesbos.nix"
                                "services"
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
                        peer-samantha = {
                            inherit self;
                            id = 550;
                            path = ./hosts/peer-samantha;
                            name = "peer-samantha";
                            tags = [
                                "lesbos.nix"
                                "peer"
                                "samantha"
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
                        srv-immich = {
                            inherit self;
                            id = 517;
                            path = ./hosts/srv-immich;
                            name = "srv-immich";
                            tags = [
                                "lesbos.nix"
                                "services"
                                # Add tags here
                            ];
                            modules = [
                                ./modules/volumes
                                ./modules/backups
                                # Add extra modules here
                            ];
                            extraSpecialArgs = {
                                pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
                                # Add extra specialArgs here
                            };
                        };
                        # @add:host:proxmox
                    };
                }
            );
}
