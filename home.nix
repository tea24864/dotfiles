{ config, pkgs, ... }: 

let 
  dotfiles = "${config.home.homeDirectory}/.dotfiles"; 
in 
{ 
  home.username = "timch"; 
  home.homeDirectory = "/home/timch"; 
  home.stateVersion = "24.11"; 

  home.packages = with pkgs; [ 
    ripgrep 
    fd 
    fzf 
    jq 
    lazygit 
    neovim 
    wezterm
  ]; 

  # DISABLED: Your VPS doesn't have an X11/Wayland desktop server to run font configs
  fonts.fontconfig.enable = false; 

  home.sessionVariables.EDITOR = "nvim"; 

  programs.zsh = { 
    enable = true; 
    autosuggestion.enable = true; 
    syntaxHighlighting.enable = true; 

    # ADD THIS TO FIX NON-INTERACTIVE SSH PATHS:
    envExtra = ''
      export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"
    '';
    # This injects the Nix paths during shell compilation. Required for wezterm remote
    initExtra = ''
      if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
      fi
    '';

    initContent = '' 
      bindkey '^f' autosuggest-accept 
    ''; 
    shellAliases = { 
      ".." = "cd .."; 
      add = "git add ."; 
      push = "git push"; 
      pull = "git pull"; 
      m = "git switch main"; 
      cc = "claude --dangerously-skip-permissions"; 
      co = "codex --full-auto"; 
    }; 
  }; 

  programs.git.settings.user = { 
    name = "tea24864"; 
    email = "tea24864@gmail.com"; 
  }; 

  programs.starship = { 
    enable = true; 
    settings = { 
      add_newline = false; 
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character"; 
      character = { 
        success_symbol = "[❯](purple)"; 
        error_symbol = "[❯](red)"; 
      }; 
      cmd_duration.format = "[$duration]($style) "; 
    }; 
  }; 

  # Symlink setups stay exactly the same.
  # Even if WezTerm isn't running on the server, keeping the symlink here is completely harmless
  home.file.".config/wezterm".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm"; 
  home.file.".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim"; 
  home.file.".config/herdr".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/herdr"; 
  home.file.".claude/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.json"; 
  home.file.".claude/CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md"; 
  home.file.".codex/AGENTS.md".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md"; 
  home.file.".config/opencode/AGENTS.md".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md"; 
}

