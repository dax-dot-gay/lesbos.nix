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
            url = "path:../common";
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
                        router = {
                            id = 500;
                            path = ./hosts/router;
                            hostConfig = {
                                thisflake = "homelab";
                                hostname = "router";
                                enable_root = true;
                                root_passhash = "$y$j9T$mQUClNbWsAEb9th3PenMR/$gpmhP8E7cgEqJqBN8DV5OGF3dkDv0Fzi4w4g8RNgJ.8";
                                enable_user = false;
                                enable_user_wheel = false;
                                username = "";
                                user_passhash = "";
                                stateVersion = "26.05";
                            };
                            name = "router";
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
