{
    description = "Flake containing common configs specific to this repository (i.e. not nixos-utilities)";
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
        #@sh:add-input
    };

    outputs =
        { self, ... }@inputs:
        let
            system = "x86_64-linux";
            pkgs = import ../../util/pkgsconf.nix {
                inherit inputs system;
                extraOverlays = [ ];
            };
        in
        {
            nixosModules = {
                default =
                    { ... }:
                    {
                        imports = [
                            inputs.sops-nix.nixosModules.sops
                            inputs.comin.nixosModules.comin
                            inputs.disko.nixosModules.disko
                            inputs.nixos-utilities.nixosModules.default
                            "${inputs.nixpkgs}/nixos/modules/virtualisation/proxmox-image.nix"
                            ./modules
                        ];
                    };
            };
            lib = {
                hydrateFlake = import ./lib/hydrateFlake.nix;
            };
        };
}
