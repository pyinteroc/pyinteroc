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
        inherit inotify-tools;

        inherit zig;
        roc = rocPkgs.cli;
        
        deployRocNightly = 
          writeShellScriptBin "deployRocNightly" ./ci/deploy_roc_nightly ;
        
        publish = 
          writeShellScriptBin "publish" ./ci/push_to_public_repos ;
          
        build = 
          writeShellScriptBin "build" "./ci/build $1" ;
          
        runtest = 
          writeShellScriptBin "runtest" "./ci/test $1" ;
        
        loop = 
          writeShellScriptBin "loop" ./ci/start_test_loop ;
      };

    in rec {
      defaultShell = pkgs.mkShell {
        buildInputs = with packageSet; [
          inotify-tools
          curl
          deployRocNightly
          publish
          build
          runtest
          loop
        ];
        shellHook = ''
          alias roc="./roc"
        '';
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