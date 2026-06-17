{ pkgs, ... }:
{
    programs.starship = {
        enable = true;
        presets = [
            "plain-text"
            "bracketed-segments"
        ];
    };
    programs.zsh.interactiveShellInit = ''
        fastfetch --config examples/8.jsonc --thread true
    '';
    environment.systemPackages = [ pkgs.fastfetch ];
}
