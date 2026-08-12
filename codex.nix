# Usage:
#   version=0.147.0
#   hash=$(nix-prefetch-url \
#     "https://github.com/openai/codex/releases/download/rust-v$version/codex-package-x86_64-unknown-linux-musl.tar.gz")
#   nix-build utils/codex.nix --argstr version "$version" --argstr hash "$hash"
{
  pkgs ? import <nixpkgs> { },
  version,
  hash,
}:

let
  inherit (pkgs) lib;
  target = "x86_64-unknown-linux-musl";
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
    wrapProgram $out/bin/codex \
      --add-flags --dangerously-bypass-approvals-and-sandbox

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
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
