{
  # Import the Nix packages collection
  pkgs ? import <nixpkgs> {},
}:

let
  # Use builtins.getFlake to obtain the local flake's outputs
  flake = builtins.getFlake (toString ./.);

  # Access the packageSet defined in the flake
  # packageSet = flake.outputs.packages.${flake.inputs.nixpkgs.system}.packageSet;

  # Optionally, you can also access other attributes from the flake, such as devShells
  devShell = flake.outputs.devShells.x86_64-linux.default;

in devShell