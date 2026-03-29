{
  description = "A basic Go development environment plus container image builder.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs }:
    let
      macSystem = "aarch64-darwin";
      linuxSystem = "x86_64-linux";

      mkLinuxApp = pkgs: pkgs.buildGoModule {
        pname = "immutable-artifact-build";
        version = "1.0.0";
        src = ./.;
        vendorHash = "sha256-NoDtIQZjxpQI8Z0FsfeH0fDD9T/aYJpmfAfbbX5S36s=";
        env.CGO_ENABLED = 0;
        env.GOOS = "linux";
        env.GOARCH = "amd64";
      };
    in
    {
      packages.${macSystem}.default =
        let
          pkgs = nixpkgs.legacyPackages.${macSystem};
          app = mkLinuxApp pkgs;
        in
        pkgs.dockerTools.buildLayeredImage {
          name = "leaks-finder";
          contents = [ app pkgs.cacert ];
          config.Cmd = [ "${app}/bin/immutable-artifact-build" ];
        };

      packages.${linuxSystem}.default =
        let
          pkgs = nixpkgs.legacyPackages.${linuxSystem};
          app = mkLinuxApp pkgs;
        in
        pkgs.dockerTools.buildLayeredImage {
          name = "leaks-finder";
          contents = [ app pkgs.cacert ];
          config.Cmd = [ "${app}/bin/immutable-artifact-build" ];
        };

      devShells.${macSystem}.default = nixpkgs.legacyPackages.${macSystem}.mkShell {
        packages = [
          nixpkgs.legacyPackages.${macSystem}.go
          nixpkgs.legacyPackages.${macSystem}.golangci-lint
        ];
      };
    };
}
