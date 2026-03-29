{
  description = "A basic Go development environment plus container image builder.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs }:
    let
      macSystem = "aarch64-darwin";
      linuxSystem = "x86_64-linux";

      mkLeaksFinder = pkgs: pkgs.buildGoModule {
        pname = "leaks-finder";
        version = "1.0.0";
        src = ./.;
        vendorHash = "sha256-NoDtIQZjxpQI8Z0FsfeH0fDD9T/aYJpmfAfbbX5S36s=";
        CGO_ENABLED = 0;
      };
    in
    {
      packages.${macSystem}.default =
        let
          pkgs = nixpkgs.legacyPackages.${macSystem};
          app = mkLeaksFinder pkgs;
        in
        pkgs.dockerTools.buildLayeredImage {
          name = "leaks-finder";
          contents = [ app pkgs.cacert ];
          config.Cmd = [ "${app}/bin/leaks-finder" ];
        };

      packages.${linuxSystem}.default =
        let
          pkgs = nixpkgs.legacyPackages.${linuxSystem};
          app = mkLeaksFinder pkgs;
        in
        pkgs.dockerTools.buildLayeredImage {
          name = "leaks-finder";
          contents = [ app pkgs.cacert ];
          config.Cmd = [ "${app}/bin/leaks-finder" ];
        };

      devShells.${macSystem}.default = nixpkgs.legacyPackages.${macSystem}.mkShell {
        packages = [
          nixpkgs.legacyPackages.${macSystem}.go
          nixpkgs.legacyPackages.${macSystem}.golangci-lint
        ];
      };
    };
}
