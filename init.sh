# Run the following command to instgall Determinate on Linux and WSL
# curl -fsSL https://install.determinate.systems/nix | sh -s -- install
# Run the following commands to initialize after Determinate Nix is installed
# . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
# nix run home-manager/master -- init --switch
#
# herdr is not managed by Nix (it self-updates into ~/.local/bin, which
# precedes ~/.nix-profile/bin on PATH). Bootstrap it once per machine:
# curl -fsSL https://herdr.dev/install.sh | sh
# Thereafter it updates itself: herdr update
