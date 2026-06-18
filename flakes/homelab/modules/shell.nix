{ pkgs, ... }:
{
    programs.zsh = {
        ohMyZsh = {
            enable = true;
            theme = "candy";
        };
    };
    environment.systemPackages = [pkgs.killall];
}
