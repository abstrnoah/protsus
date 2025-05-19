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
            symlinkJoin
            ;
        };
      in
      let
        protsus-core = upstreams.writeScriptBin "protsus-core" ''
          #!/bin/env bash
          ${builtins.readFile ./lib.sh}
          ${builtins.readFile ./main}
        '';
        protsus-rlwrapper = upstreams.writeScriptBin "protsus" ''
          #!/bin/env bash
          rlwrap -c protsus-core "$@"
        '';
        protsus-frosh-shell = upstreams.writeScriptBin "protsus-frosh-shell" ''
          #!/bin/env bash
          protsus frosh
        '';
      in
      {
        packages.default = upstreams.symlinkJoin {
          name = "protsus";
          paths = [
            protsus-core
            protsus-rlwrapper
            protsus-frosh-shell
          ];
        };
      }
    );

}
