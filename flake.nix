{
  description = "A basic Go development environment plus container image builder.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs }:
    let
      macArch = "aarch64-darwin";
      targetArch = "x86_64-linux";

      # for local development on mac m1
      macPkgs = nixpkgs.legacyPackages.${macArch};

      # target container architecture
      linuxPkgs = nixpkgs.legacyPackages.${targetArch};

      leaksFinder = linuxPkgs.buildGoModule
        {
          pname = "leaks-finder";
          version = "1.0.0";
          src = ./.;
          vendorHash = linuxPkgs.lib.fakeHash;
        };
    in
    {
      packages.${targetArch}.default = linuxPkgs.dockerTools.buildLayeredImage
        {
          name = "leaks-finder";
          tag = "latest";
          contents = [
            leaksFinder
            pkgs.cacert
          ];
          config = {
            Cmd = [ "${leaksFinder}/bin/leaks-finder" ];
          };
        };
      devShells.${macArch}.default = macPkgs.mkShell
        {
          packages = [
            macPkgs.go
            macPkgs.golangci-lint
          ];
        };
    };
}
