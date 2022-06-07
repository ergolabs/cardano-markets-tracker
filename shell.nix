let
  packages = import ./.;
  inherit (packages) pkgs cardano-markets-tracker;
  inherit (cardano-markets-tracker) haskell;

in
  haskell.project.shellFor {
    withHoogle = false;

    nativeBuildInputs = with cardano-markets-tracker; [
      hlint
      cabal-install
      haskell-language-server
      stylish-haskell
      pkgs.niv
      cardano-repo-tool
      pkgs.ghcid
      # HACK: This shouldn't need to be here.
      pkgs.lzma.dev
    ];

    buildInputs = with cardano-markets-tracker; [
      pkgs.rdkafka
    ];
  }