{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        unity = pkgs.stdenv.mkDerivation {
          name = "unity";
          src = pkgs.fetchFromGitHub {
            owner = "ThrowTheSwitch";
            repo = "Unity";
            rev = "v2.5.2";
            hash = "sha256-NokjRgBhOW9EvuZWbNGPqHlQ+OAXJMVZZJf9mXEa+YM=";
          };
          installPhase = ''
            mkdir -p $out
            cp -rv $src/* $out
          '';
        };
        cmock-gems = pkgs.bundlerEnv {
          name = "gems";
          ruby = pkgs.ruby;
          gemdir = ./.;
        };
        deps = [ cmock-gems pkgs.ruby unity];
        packageName = "cmock";
        cmock = pkgs.stdenv.mkDerivation {
          name = "cmock";
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

