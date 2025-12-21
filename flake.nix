{
  description = "Gleam Dev flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        packages.default = pkgs.stdenv.mkDerivation {
          name = "bazaar-trader";
          src = ./.;

          buildInputs = [ pkgs.gleam pkgs.elixir pkgs.erlang pkgs.rebar3 ];
          runPhase = ''
            echo hi
            ${pkgs.curl} google.com
            gleam run
          '';
        };
        devShells.default = pkgs.mkShellNoCC {
          buildInputs = [ pkgs.gleam pkgs.elixir pkgs.erlang pkgs.rebar3 ];
        };
      });
}
