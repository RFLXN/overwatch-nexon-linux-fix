{
  description = "Overwatch Nexon certificate-chain fix with NixOS runtime dependencies";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          runtimePath = pkgs.lib.makeBinPath (with pkgs; [
            bash bubblewrap openssl python3 coreutils findutils gnugrep gnused procps
          ]);
        in rec {
          overwatch-nexon-linux-fix = pkgs.stdenvNoCC.mkDerivation {
            pname = "overwatch-nexon-linux-fix";
            version = "0.1.0";
            src = self;
            dontBuild = true;
            installPhase = ''
              runHook preInstall
              mkdir -p "$out/bin"
              # Keep SELF pointing at the dependency-complete executable, including
              # doctor re-execution inside bubblewrap and Steam Linux Runtime.
              {
                echo '#!${pkgs.bash}/bin/bash'
                echo 'export PATH="${runtimePath}:$PATH"'
                tail -n +2 overwatch-nexon-linux-fix.sh
              } > "$out/bin/overwatch-nexon-linux-fix"
              chmod +x "$out/bin/overwatch-nexon-linux-fix"
              runHook postInstall
            '';
            meta = {
              description = "Per-process certificate-chain fix for Overwatch Nexon under Wine";
              license = pkgs.lib.licenses.mit;
              platforms = systems;
              mainProgram = "overwatch-nexon-linux-fix";
            };
          };
          default = overwatch-nexon-linux-fix;
        });
    };
}
