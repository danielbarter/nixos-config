# Usage:
#   nix-build codex.nix
{
  pkgs ? import <nixpkgs> { },
}:

let
  inherit (pkgs) lib;
  version = "0.166.0";
  sources = {
    x86_64-linux = {
      target = "x86_64-unknown-linux-musl";
      hash = "sha256-HUSyi8SsmTfX01MiZLqmilB842SVag1Ou4VvMxze4lQ=";
    };
    aarch64-linux = {
      target = "aarch64-unknown-linux-musl";
      hash = "sha256-eCG3fdouYoP7H2PzFlF3onHaiDPoV89nPGyhyds7/MY=";
    };
  };
  inherit (sources.${pkgs.stdenv.hostPlatform.system}
    or (throw "Unsupported Codex platform: ${pkgs.stdenv.hostPlatform.system}")) target hash;
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "codex";
  inherit version;

  src = pkgs.fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-package-${target}.tar.gz";
    inherit hash;
  };

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    # Preserve the executable and manifest for daemon package validation.
    mkdir -p $out
    cp -r bin codex-path codex-resources codex-package.json $out/
    cp ${./utils/agent-sandbox.sh} $out/bin/agent
    substituteInPlace $out/bin/agent \
      --replace-fail '@bash@' '${pkgs.bash}/bin/bash' \
      --replace-fail '@systemd_run@' '${pkgs.systemd}/bin/systemd-run' \
      --replace-fail '@binary@' "$out/bin/codex"
    chmod +x $out/bin/agent

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
