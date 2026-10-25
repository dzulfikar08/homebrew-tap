class Rustune < Formula
  desc "Terminal music player with online audio search and Winamp skin support"
  homepage "https://rustune.dzulfikar.com"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/dzulfikar08/rustune/releases/download/v0.3.7/rustune-aarch64-macos"
      sha256 "c74491763989f5e8539ca62138044179b60fbbb0fe7bc86da7763cc23d519cf5"
    end
    on_intel do
      url "https://github.com/dzulfikar08/rustune/releases/download/v0.3.7/rustune-x86_64-macos"
      sha256 "b78f7b0eea853d21960fd537f69554a85d773d62e164e04f30097ac32510deb9"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/dzulfikar08/rustune/releases/download/v0.3.7/rustune-aarch64-linux"
      sha256 "459ee7dc82773b590421016fee116aac87c51ad63ef0de01113d5ba1c4ce58fe"
    end
    on_intel do
      url "https://github.com/dzulfikar08/rustune/releases/download/v0.3.7/rustune-x86_64-linux"
      sha256 "8203f42f5bed508d8816cfa42dec3ed11d6b57d0d22524a3c0aa2036186b9f54"
    end

    depends_on "patchelf" => :build
    depends_on "alsa-lib"
  end

  def install
    binary = Dir["rustune-*"].first
    odie "rustune binary not found in download" if binary.nil?
    bin.install binary => "rustune"
    return unless OS.linux?

    # The prebuilt binary links libasound.so.2; point it at Homebrew's alsa-lib
    # so it works without a system libasound2.
    system "patchelf", "--set-rpath", formula_opt_lib("alsa-lib"), bin/"rustune"
  end

  def caveats
    <<~EOS
      Online search and streaming need yt-dlp and ffmpeg:
        brew install yt-dlp ffmpeg
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/rustune --version")
  end
end
