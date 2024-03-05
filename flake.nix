{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    buildDate = builtins.substring 0 8 self.lastModifiedDate;
    version = "0.1.0-${buildDate}";

    supportedSystems = ["x86_64-linux"];

    forAllSystems = f:
      nixpkgs.lib.genAttrs supportedSystems (system: f system);

    nixpkgsFor = forAllSystems (system:
      import nixpkgs {
        inherit system;
      });
  in {
    formatter = forAllSystems (
      system: let
        pkgs = nixpkgsFor.${system};
      in
        pkgs.alejandra
    );

    packages = forAllSystems (system: let
      pkgs = nixpkgsFor.${system};
    in {
      default = pkgs.python3Packages.buildPythonApplication rec {
        name = "py-mt-${version}";
        src = ./.;
        buildInputs = with pkgs; [
          python3
          python3.pkgs.fastapi
        ];

        nativeBuildInputs = with pkgs; [
          python3.pkgs.setuptools
          python3.pkgs.wheel
          python3.pkgs.uvicorn
        ];
      };
    });

    devShells.default = forAllSystems (system: let
      pkgs = nixpkgsFor.${system};
    in
      pkgs.mkShell rec {
        NIX_CONFIG = "experimental-features = nix-command flakes";
        buildInputs = with pkgs; [
          python3
          python3.pkgs.fastapi
        ];

        nativeBuildInputs = with pkgs; [
          python3.pkgs.setuptools
          python3.pkgs.wheel
          python3.pkgs.uvicorn
        ];
      });
  };
}
