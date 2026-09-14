# Usage:
#   nix-build codex.nix
{
  pkgs ? import <nixpkgs> { },
  sandboxed ? true,
}:

let
  inherit (pkgs) lib;
  version = "0.154.0";
  sources = {
    x86_64-linux = {
      target = "x86_64-unknown-linux-musl";
      hash = "sha256-/G4+O4Xyz31mRSDuXGan/kqhK659RoNPR+LxZf0Nb3g=";
    };
    aarch64-linux = {
      target = "aarch64-unknown-linux-musl";
      hash = "sha256-l9k+Ed9y08JnctsBnm6ou3LCRlANRrmMdgg58yQDVeY=";
    };
  };
  inherit (sources.${pkgs.stdenv.hostPlatform.system}
    or (throw "Unsupported Codex platform: ${pkgs.stdenv.hostPlatform.system}")) target hash;
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "codex";
  inherit version;

  nativeBuildInputs = [ pkgs.makeWrapper ];

  src = pkgs.fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-package-${target}.tar.gz";
    inherit hash;
  };

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r bin codex-path codex-resources codex-package.json $out/
    ${
      if sandboxed then
        ''
          mv $out/bin/codex $out/bin/codex-unwrapped
          makeWrapper ${pkgs.systemd}/bin/systemd-run $out/bin/codex \
            --add-flags "--user --pty -p WorkingDirectory=\$(pwd) -p InaccessiblePaths=-/cold $out/bin/codex-unwrapped --dangerously-bypass-approvals-and-sandbox"
        ''
      else
        ''
          wrapProgram $out/bin/codex \
            --add-flags --dangerously-bypass-approvals-and-sandbox
        ''
    }

    runHook postInstall
  '';

  # The release binary is a static PIE and must not be patched to use Nix's
  # dynamic linker.
  dontPatchELF = true;
  strictDeps = true;

  meta = {
    description = "Lightweight coding agent that runs in your terminal";
    homepage = "https://github.com/openai/codex";
    license = lib.licenses.asl20;
    mainProgram = "codex";
    platforms = builtins.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
