{
  description = "A basic Go development environment.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell
        {
          packages = [
            pkgs.go
            pkgs.golangci-lint
          ];
        };
    };
}
