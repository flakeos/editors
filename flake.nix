{
  description = "Multi-editor configuration manager for VSCode-family editors";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"
      ];
    in {
      packages = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
          editors = pkgs.callPackage ./nix/editors.nix { };
          default = self.packages.${system}.editors;
        });

      homeManagerModules = {
        editors = import ./nix/hm-module.nix;
        default = self.homeManagerModules.editors;
      };

      checks = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
          editors = self.packages.${system}.editors;
        });

      formatter = forAllSystems (system:
        nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
