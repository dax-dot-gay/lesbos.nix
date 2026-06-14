{
    description = "Flake containing common configs specific to this repository (i.e. not nixos-utilities)";
    inputs = {
        inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
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
        { self, ... }@inputs:
        let
            system = "x86_64-linux";
            pkgs = import ../../util/pkgsconf.nix {
                inherit inputs system;
                extraOverlays = [ ];
            };
        in
        {
        };
}
