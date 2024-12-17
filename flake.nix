{
  description = "A developer environment for walle.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
    devenv.url = "github:cachix/devenv";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs = {
    self,
    nixpkgs,
    devenv,
    systems,
    ...
  } @ inputs: let
    forEachSystem = nixpkgs.lib.genAttrs (import systems);
  in {
    devShells = forEachSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      walle-dev = devenv.lib.mkShell {
        inherit inputs pkgs;
        modules = [
          {
            packages = with pkgs; [
              catch2_3
              cmake
              doxygen
              gcc
              gdb
              gtest
              llvmPackages_19.libllvm
              zlib
            ];

            pre-commit.hooks = {
              clang-format.enable = true;
              clang-tidy.enable = true;
            };

            scripts.build-walle.exec = ''
              cmake -S . -B build
              cmake --build build
            '';

            scripts.test-walle.exec = ''
              cmake -S . -B build -DBUILD_TESTS=true
              cmake --build build
              ./build/tests/walle-tests
            '';
          }
        ];
      };
    });
  };
}
