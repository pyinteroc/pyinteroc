{
  description = "A development environment for Python, zig and ROC";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    roc.url = "github:roc-lang/roc";

  };

  outputs = { self, nixpkgs, roc, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      rocPkgs = roc.packages.${system};


      # Define packages as an attribute set
      packageSet = with pkgs; {
        inherit entr;
        inherit zig;

        ### add roc command
        roc = rocPkgs.cli;
        
        
        ### add deployRocNightly script and utilities
        inherit curl;
        
        deployRocNightly = 
          writeShellScriptBin "deployRocNightly" ./ci/deploy_roc_nightly.sh ;
        
        publish = 
          writeShellScriptBin "publish" ./ci/push_to_public_repos.sh ;
        
      };

    in rec {
      defaultShell = pkgs.mkShell {
        buildInputs = with packageSet; [

          ### utilities
          entr
          curl
          deployRocNightly
          publish
          
          
        ];

      };
      
      ### defining available shells
      devShells.${system} = {
        default = defaultShell;

        allPackages = pkgs.mkShell {
          # Convert the attribute set to a list for buildInputs
          buildInputs = builtins.attrValues packageSet;
          shellHook = ''alias roc="./roc"'';
        };
      };
      
      ### Assign the attribute set directly to packages
      packages = packageSet;

    };
}