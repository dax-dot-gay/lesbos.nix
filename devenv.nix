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
        yq-go
        mkpasswd
        killall
        openssl
        mo
        pwgen-secure
        inetutils
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
    dotenv.enable = true;
    scripts = {
        doohickey.exec = '' #bash
            export CALLPWD=$PWD
            cd $(git rev-parse --show-toplevel)
            ./scripts/doohickey/doohickey.sh $@
        '';
    };
    enterShell = '' #bash
        cd $(git rev-parse --show-toplevel)
        ./scripts/get_lobash.sh
    '';
}
