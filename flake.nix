{
  description = "The most basic dynamic function row daemon possible";
  inputs = { nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11"; };
  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in rec {
      packages = forAllSystems (system:
        let pkgs = pkgsFor.${system};
        in {
          default = pkgs.rustPlatform.buildRustPackage {
            pname = "tiny-dfr";
            version = "0.3.5";
            src = ./.;
            cargoLock = { lockFile = ./Cargo.lock; };
            nativeBuildInputs = [ pkgs.pkg-config ];
            buildInputs = [
              pkgs.cairo
              pkgs.libinput
              pkgs.freetype
              pkgs.fontconfig
              pkgs.glib
              pkgs.pango
              pkgs.gdk-pixbuf
              pkgs.libxml2
              pkgs.librsvg
            ];

            postConfigure = ''
              substituteInPlace etc/systemd/system/tiny-dfr.service \
                  --replace-fail /usr/bin $out/bin
              substituteInPlace src/*.rs --replace-quiet /usr/share $out/share
            '';

            postInstall = ''
              cp -R etc $out/lib
              cp -R share $out
            '';
          };
        });

      devShells = forAllSystems (system:
        let pkgs = pkgsFor.${system};
        in {
          default = pkgs.mkShell {
            inputsFrom = [ packages.${system}.default ];
            packages = [ pkgs.rustfmt pkgs.rust-analyzer ];
            RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
          };
        });
    };
}
