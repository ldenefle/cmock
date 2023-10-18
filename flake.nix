{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    Unity.url = "github:ldenefle/Unity";
  };

  outputs = { self, nixpkgs, flake-utils, Unity }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        unity = Unity.packages.${system}.default;

        cmock-gems = pkgs.bundlerEnv {
          name = "gems";
          ruby = pkgs.ruby;
          gemdir = ./.;
        };
        deps = [ cmock-gems pkgs.ruby unity];
        packageName = "cmock";
        cmock = pkgs.stdenv.mkDerivation {
          name = packageName;
          src = ./.;
          propagatedBuildInputs = deps;
          installPhase = ''
            mkdir -p $out
            cp -rv $src/* $out
          '';
        };

      in with pkgs;
      {
        devShells.default =
          mkShell {
            buildInputs = deps;
            shellHook = ''
              export UNITY_DIR=${unity};
            '';
          };

        packages.${packageName} = cmock;

        defaultPackage = self.packages.${system}.${packageName};

        packages.default = cmock;

        dependencies.unity = unity;
      }
    );
}

