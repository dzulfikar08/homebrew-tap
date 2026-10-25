#!/usr/bin/env bash
# Regenerate Formula/rustune.rb from the latest rustune GitHub release.
# Requires: gh (authenticated, e.g. GH_TOKEN), jq, curl, sha256sum or shasum.
set -euo pipefail

REPO="dzulfikar08/rustune"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FORMULA="$ROOT/Formula/rustune.rb"

release_json="$(gh api "repos/$REPO/releases/latest")"
tag="$(jq -r '.tag_name' <<<"$release_json")"
version="${tag#v}"

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

has_asset() {
  jq -e --arg n "$1" 'any(.assets[]; .name == $n)' <<<"$release_json" >/dev/null
}

asset_url() {
  jq -r --arg n "$1" '.assets[] | select(.name == $n) | .browser_download_url' <<<"$release_json"
}

# sha256 from the asset digest, falling back to downloading the asset.
asset_sha() {
  local name="$1" digest tmp
  digest="$(jq -r --arg n "$name" '.assets[] | select(.name == $n) | .digest // empty' <<<"$release_json")"
  if [[ "$digest" == sha256:* ]]; then
    echo "${digest#sha256:}"
    return
  fi
  tmp="$(mktemp)"
  curl -fsSL -o "$tmp" "$(asset_url "$name")"
  sha256_file "$tmp"
  rm -f "$tmp"
}

for required in rustune-aarch64-macos rustune-x86_64-macos rustune-x86_64-linux; do
  if ! has_asset "$required"; then
    echo "error: release $tag is missing required asset $required" >&2
    exit 1
  fi
done

block() {
  local indent="$1" name="$2"
  printf '%surl "%s"\n' "$indent" "$(asset_url "$name")"
  printf '%ssha256 "%s"\n' "$indent" "$(asset_sha "$name")"
}

linux_blocks() {
  if has_asset rustune-aarch64-linux; then
    echo "    on_arm do"
    block "      " rustune-aarch64-linux
    echo "    end"
  fi
  echo "    on_intel do"
  block "      " rustune-x86_64-linux
  echo "    end"
}

mkdir -p "$(dirname "$FORMULA")"
cat >"$FORMULA" <<EOF
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
$(block "      " rustune-aarch64-macos)
    end
    on_intel do
$(block "      " rustune-x86_64-macos)
    end
  end

  on_linux do
$(linux_blocks)

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
EOF

echo "Generated $FORMULA for rustune $version"
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "version=$version" >>"$GITHUB_OUTPUT"
fi
