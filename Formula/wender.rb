class Wender < Formula
  desc "Transfer files and directories between devices over WiFi"
  # The source repository is private; this is the public distribution point users can open.
  homepage "https://github.com/bartwell/wender-cli"
  version "6.6.5"
  # Free to use, closed source: not expressible as an SPDX identifier.
  license :cannot_represent

  # Each archive already contains a jlink-trimmed Java runtime, so the formula declares no
  # dependency on a JDK and nothing is compiled at install time.
  # Apple Silicon only: GitHub retired the Intel macOS runners, and an arm64 build cannot serve an
  # Intel Mac — Rosetta translates x86 to arm, not the reverse.
  on_macos do
    url "https://github.com/bartwell/wender-cli/releases/download/v6.6.5/wender-6.6.5-macos-arm64.tar.gz"
    sha256 "a12e2df54fa8957c305a57cb3085f63bce912a20db651c198dfb2d4e2a5ecc44"
  end

  on_linux do
    on_arm do
      url "https://github.com/bartwell/wender-cli/releases/download/v6.6.5/wender-6.6.5-linux-arm64.tar.gz"
      sha256 "a986d3fb6268e7ad0a9f3f78150dcfea9a78b58fccabda7e05a1830f339e0c65"
    end
    on_intel do
      url "https://github.com/bartwell/wender-cli/releases/download/v6.6.5/wender-6.6.5-linux-x64.tar.gz"
      sha256 "326f901b0a003a7fa087a07c8af4f5448b7b2359fc7dd015c3a213b1a4e10b54"
    end
  end

  def install
    if OS.mac?
      # jpackage always produces an .app bundle on macOS, even for a console tool. Keeping the
      # bundle intact in libexec and exposing only the launcher gives the usual CLI experience
      # without fighting the packaging format.
      libexec.install "wender.app"
      bin.install_symlink libexec/"wender.app/Contents/MacOS/wender"
    else
      libexec.install Dir["wender/*"]
      bin.install_symlink libexec/"bin/wender"
    end
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/wender --version")
  end
end
