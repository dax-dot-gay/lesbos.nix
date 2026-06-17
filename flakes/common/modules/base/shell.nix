{ pkgs, ... }:
{
    users.defaultUserShell = pkgs.zsh;
    programs.zsh = {
        enable = true;
        autosuggestions = {
            enable = true;
            strategy = [
                "completion"
                "history"
            ];
        };
        enableCompletion = true;
        enableLsColors = true;
        syntaxHighlighting = {
            enable = true;
        };
    };
    environment.systemPackages = with pkgs; [
        btop
        git
        neovim
        ghostty.terminfo
        bat
    ];
}
