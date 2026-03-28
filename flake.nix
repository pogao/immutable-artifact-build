{
  description = "A basic Go development environment plus container image builder.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs }:
    let
      # Define our two specific systems
      macSystem = "aarch64-darwin";
      linuxSystem = "x86_64-linux";

      # Function to create the Go package for a specific system
      mkLeaksFinder = pkgs: pkgs.buildGoModule {
        pname = "leaks-finder";
        version = "1.0.0";
        src = ./.;
        # Using a fake hash to trigger the error that gives us the real one
        vendorHash = "sha256-NoDtIQZjxpQI8Z0FsfeH0fDD9T/aYJpmfAfbbX5S36s=";
      };
    in
    {
      # Standard Nix Flake output format: packages.<system>.<name>
      packages.${macSystem}.default = let pkgs = nixpkgs.legacyPackages.${macSystem}; in
        pkgs.dockerTools.buildLayeredImage {
          name = "leaks-finder";
          contents = [ (mkLeaksFinder pkgs) pkgs.cacert ];
          config.Cmd = [ "leaks-finder" ];
        };

      packages.${linuxSystem}.default = let pkgs = nixpkgs.legacyPackages.${linuxSystem}; in
        pkgs.dockerTools.buildLayeredImage {
          name = "leaks-finder";
          contents = [ (mkLeaksFinder pkgs) pkgs.cacert ];
          config.Cmd = [ "leaks-finder" ];
        };

      devShells.${macSystem}.default = nixpkgs.legacyPackages.${macSystem}.mkShell {
        packages = [
          nixpkgs.legacyPackages.${macSystem}.go
          nixpkgs.legacyPackages.${macSystem}.golangci-lint
        ];
      };
    };
}
