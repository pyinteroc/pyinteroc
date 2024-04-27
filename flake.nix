{
  description = "A development environment for Python, zig and ROC";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    roc.url = "github:roc-lang/roc";

  };

  outputs = { self, nixpkgs, flake-utils, roc, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        rocPkgs = roc.packages.${system};

        roc-nightly-url = "https://github.com/roc-lang/roc/releases/download/nightly/roc_nightly-linux_x86_64-latest.tar.gz";
        
        deployRocNightly = pkgs.writeShellScriptBin "deployRocNightly" ''
          if [ ! -d "crates" ]; then
            curl -L ${roc-nightly-url} -o roc_nightly.tar.gz
            tar -xzvf roc_nightly.tar.gz
            rm -rf roc_nightly.tar.gz
            mv roc_nightly* roc_nightly
            cp -r roc_nightly/crates/ crates/
            cp roc_nightly/roc roc
            rm -rf roc_nightly/
          fi

          '';
        
        # Define packages as an attribute set
        packageSet = with pkgs; {
          inherit entr;
          inherit zig;

          ### add deployRocNightly script and utilities
          inherit deployRocNightly;
          inherit curl;
          
          ### add roc command
          roc = rocPkgs.cli;
          
        };

      in rec {
        defaultShell = pkgs.mkShell {
          buildInputs = with packageSet; [
            entr
            curl
            deployRocNightly
          ];

        };
        
        ### defining available shells
        devShells = {
          default = defaultShell;

          allPackages = pkgs.mkShell {
            # Convert the attribute set to a list for buildInputs
            buildInputs = builtins.attrValues packageSet;
            shellHook = ''alias roc="./roc"'';
          };
        };
        
        ### Assign the attribute set directly to packages
        packages = packageSet;

        defaultPackage = self.packages.${system}.deployRocNightly;
      }
    );
}