{ pkgs, inputs, ... }:

{
    packages = with pkgs; [
        git
        argc
        openssh
        inputs.nixos-anywhere.packages.x86_64-linux.nixos-anywhere
        sops
        ssh-to-age
        age
        jq
    ];
    languages.python = {
        enable = true;
        venv = {
            enable = true;
            requirements = ''
                proxctl==0.2.8
            '';
        };
    };
}
