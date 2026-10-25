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
      url "https://github.com/dzulfikar08/rustune/releases/download/v0.3.6/rustune-aarch64-macos"
      sha256 "e1b551ab4c2607ae11c9b9e158c79d7295b4594843a784aaa7f96f70ed680556"
    end
    on_intel do
      url "https://github.com/dzulfikar08/rustune/releases/download/v0.3.6/rustune-x86_64-macos"
      sha256 "f80c276355f0110ca0ac8b149e27d34c3b99ec79a9f9670fb18a557395e22839"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/dzulfikar08/rustune/releases/download/v0.3.6/rustune-x86_64-linux"
      sha256 "5668e4945d6bdf617cf580bfebf835b4fdd76bafb4580a4bf1509ee1c8afeae9"
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
