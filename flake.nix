{
  description = "A development environment for Python, zig and ROC";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    roc.url = "github:roc-lang/roc";
  };

  outputs = { self, nixpkgs, roc, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      rocPkgs = roc.packages.${system};

      packageSet = with pkgs; {
        inherit curl;
        inherit entr;

        inherit zig;
        roc = rocPkgs.cli;
        
        deployRocNightly = 
          writeShellScriptBin "deployRocNightly" ./ci/deploy_roc_nightly.sh ;
        
        publish = 
          writeShellScriptBin "publish" ./ci/push_to_public_repos.sh ;
      };

    in rec {
      defaultShell = pkgs.mkShell {
        buildInputs = with packageSet; [
          entr
          curl
          deployRocNightly
          publish
        ];
      };
      
      devShells.${system} = {
        default = defaultShell;

        allPackages = pkgs.mkShell {
          buildInputs = builtins.attrValues packageSet;
        };
      };
      
      packages = packageSet;

    };
}