{
  description = "nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      nix-homebrew,
    }:
    let
      configuration =
        { pkgs, config, ... }:
        {
          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          environment.systemPackages = [
            pkgs.brave
            pkgs.keepassxc
            pkgs.syncthing
            pkgs.skhd
            pkgs.yabai
            pkgs.discord
            pkgs.signal-desktop
            pkgs.clojure
            pkgs.ripgrep
            pkgs.cargo
            pkgs.nixfmt-rfc-style
            pkgs.zoom-us
            pkgs.netflix
            pkgs.quarto
            pkgs.stow
          ];

          # Setting MacOS settings
          system.defaults = {
            dock.autohide = true;
            finder.FXPreferredViewStyle = "clmv";
            NSGlobalDomain.AppleInterfaceStyle = "Dark";
            NSGlobalDomain.KeyRepeat = 2;
            screencapture.location = "~/Pictures/screenshots";

            # For yabai
            spaces.spans-displays = false;
            WindowManager.EnableStandardClickToShowDesktop = false;
          };
          system.keyboard = {
            enableKeyMapping = true;
            remapCapsLockToEscape = true;
          };

          # Setting up Homebrew
          homebrew = {
            enable = true;
            casks = [
              "obs"
              "raycast"
            ];
            onActivation.cleanup = "zap";
            onActivation.autoUpdate = true;
            onActivation.upgrade = true;
          };

          services.yabai = {
            enable = true;
            config = {
              layout = "bsp";
              top_padding = "0";
              bottom_padding = "0";
              left_padding = "0";
              right_padding = "0";
              window_gap = "0";
              focus_follows_mouse = "autoraise";
              mouse_follows_focus = "on";
              window_placement = "second_child";
            };
          };

          services.skhd = {
            enable = true;
          };

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # Enable alternative shell support in nix-darwin.
          # programs.fish.enable = true;

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 5;

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";

          users.users.falcon = {
            name = "falcon";
            home = "/Users/falcon";
          };

        };
      homeconfig =
        { pkgs, ... }:
        {
          home.stateVersion = "24.05";

          home.sessionVariables = {
            EDITOR = "nvim";
          };

          programs.nushell = {
            enable = true;
            shellAliases = {
              rebuild = "darwin-rebuild switch --flake ~/nix#egg";
              keepass = "${pkgs.keepassxc}/Applications/KeePassXC.app/Contents/MacOS/KeePassXC";
              signal = "${pkgs.signal-desktop}/Applications/Signal.app/Contents/MacOS/Signal";
            };
            extraConfig = ''
              $env.config = {
                show_banner: false,
              }
            '';
          };

          programs.zsh = {
            enable = true;
            shellAliases = {
              rebuild = "darwin-rebuild switch --flake ~/nix#egg";
              keepass = "${pkgs.keepassxc}/Applications/KeePassXC.app/Contents/MacOS/KeePassXC";
              signal = "${pkgs.signal-desktop}/Applications/Signal.app/Contents/MacOS/Signal";
            };
          };

          programs.fzf = {
            enable = true;
          };

          programs.zoxide = {
            enable = true;
            enableZshIntegration = true;
            enableNushellIntegration = true;
          };

          programs.starship = {
            enable = true;
            enableZshIntegration = true;
            enableNushellIntegration = true;
          };

          programs.wezterm = {
            enable = true;
          };

          programs.neovim = {
            enable = true;
            viAlias = true;
            vimAlias = true;
            vimdiffAlias = true;
          };

          programs.git = {
            enable = true;
            userName = "orbit-stabilizer";
            userEmail = "orbit-stabilizer@tuta.io";
            extraConfig = {
              init.defaultBranch = "main";
            };
          };
        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#egg
      darwinConfigurations."egg" = nix-darwin.lib.darwinSystem {
        specialArgs.pkgs = import nixpkgs {
          system = "aarch64-darwin";
          config.allowUnfree = true;
        };
        modules = [
          configuration
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              verbose = true;
              users.falcon = homeconfig;
            };
          }
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              # Apple Silicon Only
              enableRosetta = true;
              # User owning Homebrew prefix
              user = "falcon";
            };
          }
        ];
      };
    };
}
