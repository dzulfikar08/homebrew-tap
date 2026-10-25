# dzulfikar08/homebrew-tap

Homebrew tap for [rustune](https://github.com/dzulfikar08/rustune), a terminal music player with online audio search, local playback, and Winamp skin support.

## Install

```sh
brew install dzulfikar08/tap/rustune
```

Supported: macOS (Apple Silicon and Intel) and Linux x86_64, plus Linux arm64 for releases that ship an arm64 build.

For online search and streaming, also install:

```sh
brew install yt-dlp ffmpeg
```

## Updates

The formula tracks the latest rustune GitHub release and is regenerated automatically every 6 hours by the `update` workflow. Upgrade with:

```sh
brew upgrade rustune
```
