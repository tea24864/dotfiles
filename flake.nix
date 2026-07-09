{
  description = "dotfiles";

  inputs = {
    # Standard Linux version of nixpkgs matching the instructor's release cycle
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    herdr.url = "github:ogulcancelik/herdr";
    
    # Standard Linux release of Home Manager
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, herdr, home-manager, nixpkgs }: {
    homeConfigurations."ubuntu" = home-manager.lib.homeManagerConfiguration {
      # Sets up standard 64-bit Linux package compilation
      pkgs = nixpkgs.legacyPackages.x86_64-linux; 
      
      modules = [
        # Points directly to the instructor's user profile settings
        ./home.nix 
        {
          # Absolute requirements for running Home Manager standalone on Ubuntu
          home.username = "timch";
          home.homeDirectory = "/home/timch"; 
          
          # Allows Home Manager to manage itself cleanly
          programs.home-manager.enable = true; 

          # herdr has no HM module yet — install the binary directly
          home.packages = [ herdr.packages.x86_64-linux.default ];
        }
      ];
    };
  };
}

