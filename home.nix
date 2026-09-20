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
    # wezterm is deliberately NOT installed here: it is a GPU-accelerated GUI
    # app, so on this non-NixOS host it comes from apt (WezTerm's own
    # apt.fury.io/wez repo), which links against the system Mesa/X11 stack.
    # Home Manager still manages ~/.config/wezterm below.
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
      export PATH="export PATH=$HOME/.opencode/bin:$HOME/.local/bin:$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"
    '';

    initContent = '' 
      bindkey '^f' autosuggest-accept 
      # This injects the Nix paths during shell compilation. Required for wezterm remote
      if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
      fi
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

  # kirk autologins timch (lightdm `autologin-user`), so the XFCE session - and
  # with it everything in ~/.config/autostart - comes up at boot with nobody at
  # the keyboard. That is the hook this entry hangs off: one WezTerm window
  # whose program is herdr, which reattaches the persistent session rather than
  # opening an empty shell.
  #
  # Both paths are absolute on purpose. The session runs Exec= without a shell,
  # so ~/.local/bin (where herdr's own updater installs it) is not on PATH, and
  # /usr/bin/wezterm names the apt build explicitly - the same reason wezterm is
  # kept out of home.packages. Panes herdr spawns are shells and do read
  # .zshenv, so only this one line needs the full paths.
  xdg.configFile."autostart/herdr.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Herdr
    Comment=Persistent Herdr session in WezTerm
    Exec=/usr/bin/wezterm start --cwd ${config.home.homeDirectory} -- ${config.home.homeDirectory}/.local/bin/herdr
    Terminal=false
  '';

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

