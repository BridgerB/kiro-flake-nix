{
  description = "Kiro - The AI IDE for prototype to production";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    utils,
  }:
    utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };

      # Required libraries for Kiro
      libPath = with pkgs;
        lib.makeLibraryPath [
          # Graphics libraries
          libGL
          libGLU
          libdrm
          mesa
          libgbm

          # Audio libraries
          alsa-lib
          libpulseaudio

          # GUI libraries
          atk
          at-spi2-atk
          at-spi2-core
          cairo
          gdk-pixbuf
          glib
          gtk3
          pango

          # System libraries
          cups
          dbus
          expat
          fontconfig
          freetype
          libuuid
          libxkbcommon
          libxml2
          nspr
          nss
          systemd
          zlib

          # X11 libraries
          xorg.libX11
          xorg.libXcomposite
          xorg.libXcursor
          xorg.libXdamage
          xorg.libXext
          xorg.libXfixes
          xorg.libXi
          xorg.libXrandr
          xorg.libXrender
          xorg.libXtst
          xorg.libxcb
        ];
    in {
      packages.default = with pkgs;
        stdenv.mkDerivation {
          pname = "kiro";
          version = "0.1.0";
          src = ./.;

          nativeBuildInputs = [patchelf];

          installPhase = ''
            mkdir -p $out/bin $out/lib/kiro

            # Copy all files from the source directory
            cp -r $src/* $out/lib/kiro/

            # Move the main binary to the lib directory
            mv $out/lib/kiro/kiro $out/lib/kiro/kiro-bin

            # Make binaries executable
            chmod +w $out/lib/kiro/kiro-bin
            chmod +x $out/lib/kiro/kiro-bin
            chmod +x $out/lib/kiro/chrome-sandbox
            chmod +x $out/lib/kiro/chrome_crashpad_handler

            # Create symbolic links for libraries in the standard location
            ln -s $out/lib/kiro/libffmpeg.so $out/lib/libffmpeg.so
            ln -s $out/lib/kiro/libEGL.so $out/lib/libEGL.so
            ln -s $out/lib/kiro/libGLESv2.so $out/lib/libGLESv2.so
            ln -s $out/lib/kiro/libvk_swiftshader.so $out/lib/libvk_swiftshader.so
            ln -s $out/lib/kiro/libvulkan.so.1 $out/lib/libvulkan.so.1

            # Patch the binary to find libraries
            patchelf --set-rpath $out/lib/kiro:${libPath} $out/lib/kiro/kiro-bin

            # Create a wrapper script
            cat > $out/bin/kiro << EOF
            #!/bin/bash
            export LD_LIBRARY_PATH="$out/lib/kiro:${libPath}"
            export CHROME_DESKTOP=Kiro
            exec $out/lib/kiro/kiro-bin "\$@"
            EOF
                        chmod +x $out/bin/kiro
          '';

          meta = with lib; {
            description = "Kiro - An AI coding assistant";
            homepage = "https://kiro.dev";
            license = licenses.unfree;
            platforms = platforms.linux;
          };
        };

      apps.default = {
        type = "app";
        program = "${self.packages.${system}.default}/bin/kiro";
      };
    });
}
