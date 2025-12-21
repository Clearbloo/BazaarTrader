FROM nixos/nix

ENV LANG=en_GB.UTF-8 \
    LC_ALL=en_GB.UTF-8

RUN nix-channel --add https://nixos.org/channels/nixos-unstable nixpkgs
RUN nix-channel --update
RUN nix-channel --list
RUN nix-env -iA nixpkgs.glibcLocales nixpkgs.glibc_multi
RUN echo "en_GB.UTF-8/UTF-8" > /etc/locale.gen
RUN localedef -i en_GB -f UTF-8 en_GB.UTF-8
RUN nix-env -iA nixpkgs.gleam nixpkgs.elixir nixpkgs.erlang nixpkgs.rebar3 
RUN echo gleam --version


WORKDIR /app

COPY ./src ./src
COPY ./flake.nix ./flake.nix
COPY ./flake.lock ./flake.lock
COPY ./gleam.toml ./gleam.toml

RUN mix local.hex --force
ENTRYPOINT ["gleam", "run"]
