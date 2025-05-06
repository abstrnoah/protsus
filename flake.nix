{
  description = "Protect suspicious evidence from the crewmates";

  inputs.systems.url = "github:nix-systems/default-linux";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.flake-utils.inputs.systems.follows = "systems";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

  outputs = inputs@{ ... }:
    inputs.flake-utils.lib.eachDefaultSystem (system:
      let
        upstreams = {
          inherit (inputs.nixpkgs.legacyPackages.${system})
            writeShellApplication coreutils;
        };
      in {
      # TODO
      });

}
