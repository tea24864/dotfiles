-- WezTerm configuration for this workstation.
--
-- Home Manager points ~/.config/wezterm at this directory with
-- mkOutOfStoreSymlink (see home.nix), so edits here take effect without a
-- `home-manager switch`; WezTerm hot-reloads the file on save.
--
-- WezTerm itself is installed from apt (WezTerm own apt.fury.io/wez repo)
-- rather than from Nix, because it is a GPU-accelerated GUI app that has to
-- link against the system Mesa/X11 stack. Only this config is managed here.

local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- WezTerm is apt-managed on this host, so its built-in update check can only
-- ever advertise a build we would not install through it.
config.check_for_updates = false

-- Herdr is the multiplexer inside this terminal and keeps its own scrollback,
-- so WezTerm scrollback only really serves the plain shell tabs.
config.scrollback_lines = 10000

return config
