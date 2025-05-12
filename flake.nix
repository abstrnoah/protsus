{
  description = "Protect suspicious evidence from the crewmates";

  inputs.systems.url = "github:nix-systems/default-linux";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.flake-utils.inputs.systems.follows = "systems";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

  outputs =
    inputs@{ ... }:
    inputs.flake-utils.lib.eachDefaultSystem (
      system:
      let
        upstreams = {
          inherit (inputs.nixpkgs.legacyPackages.${system})
            writeScriptBin
            coreutils
            ;
          inherit (inputs.nixpkgs.lib.attrsets) genAttrs;
        };
      in
      let
        make_cla =
          name:
          upstreams.writeScriptBin name ''
            #!/bin/env bash
            ${builtins.readFile ./lib.sh}
            ${name} "$@"
          '';
        commands = [
          "cat"
          "cd"
          "feh"
          "lock"
          "ls"
          "open"
          "protect"
          "unlock"
        ];
      in
      {
        packages = upstreams.genAttrs commands make_cla;
      }
    );

}
