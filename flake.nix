{
  description = "Gleam Dev flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        gleam = pkgs.rustPlatform.buildRustPackage rec {
          pname = "gleam";
          version = "1.9.0";

          src = pkgs.fetchFromGitHub {
            owner = "gleam-lang";
            repo = pname;
            tag = "v${version}";
            hash = "sha256-+06ZxeBYxpp8zdpxGolBW8FCrCf8vdt1RO2z9jkDGbg=";
          };

          cargoHash = "sha256-RV+AghBBCHjbp+rgQiftlHUPuzigMkvcQHjbs4Lewvs=";

          nativeBuildInputs = with pkgs; [ git pkg-config ];
          buildInputs = with pkgs; [ openssl erlang ];
          useFetchCargoVendor = true;

          # If needed, you can disable specific tests
          # cargoTestFlags = [ "--test-threads" "1" ];

          # passthru.updateScript = nix-update-script { };

          meta = with pkgs.lib; {
            description = "Statically typed language for the Erlang VM";
            mainProgram = "gleam";
            homepage = "https://gleam.run/";
            changelog =
              "https://github.com/gleam-lang/gleam/blob/v${version}/CHANGELOG.md";
            license = licenses.asl20;
            maintainers = teams.beam.members ++ [ lib.maintainers.philtaken ];
          };

        };
      in {
        packages.default = gleam;

        # For use with `nix develop`
        devShells.default = pkgs.mkShellNoCC {
          buildInputs = [
            gleam
            # pkgs.erlang
            # pkgs.rebar3
          ];
        };
      });
}
