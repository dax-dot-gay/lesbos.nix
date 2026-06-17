{ pkgs, ... }:
{
    programs.zsh = {
        ohMyZsh = {
            enable = true;
            theme = "candy";
        };
        interactiveShellInit = ''
            afetch
        '';
    };
    environment.systemPackages = [pkgs.afetch];
}
