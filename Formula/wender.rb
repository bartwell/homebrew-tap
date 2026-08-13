class Wender < Formula
  desc "Transfer files and directories between devices over WiFi"
  # The source repository is private; this is the public distribution point users can open.
  homepage "https://github.com/bartwell/wender-cli"
  version "6.6.9"
  # Free to use, closed source: not expressible as an SPDX identifier.
  license :cannot_represent

  # Each archive already contains a jlink-trimmed Java runtime, so the formula declares no
  # dependency on a JDK and nothing is compiled at install time.
  # Apple Silicon only: GitHub retired the Intel macOS runners, and an arm64 build cannot serve an
  # Intel Mac — Rosetta translates x86 to arm, not the reverse.
  on_macos do
    url "https://github.com/bartwell/wender-cli/releases/download/v6.6.9/wender-6.6.9-macos-arm64.tar.gz"
    sha256 "f942c0cfbd13e0adfbac7bd3f420c7667d985d92bf6c3f52f543e12d7ee0b8e2"
  end

  on_linux do
    on_arm do
      url "https://github.com/bartwell/wender-cli/releases/download/v6.6.9/wender-6.6.9-linux-arm64.tar.gz"
      sha256 "0e3c0e47ee5bedd737b69dc73d11b2581facf2777865ed7c0408d3d2de62f7fa"
    end
    on_intel do
      url "https://github.com/bartwell/wender-cli/releases/download/v6.6.9/wender-6.6.9-linux-x64.tar.gz"
      sha256 "4b3443be4b2826a566f615645b5027245d518c81580e0c5f73cac95ab6abc4ad"
    end
  end

  # Each archive unpacks to a versioned directory -- wender-<version>/wender.app on macOS,
  # wender-<version>/wender elsewhere -- and Homebrew descends into that single top-level directory
  # before this runs, which is why the paths below start inside it. The wrapper directory is there
  # for exactly that reason: an archive rooted directly at wender.app left this block standing in the
  # bundle with nothing to install, and every `brew install wender` failed with ENOENT.
  #
  # Both branches expose the launcher with an exec script rather than the symlink install_symlink
  # would write and Homebrew would normally prefer. A jpackage launcher works out where its runtime
  # lives from its own argv[0], and the macOS one, handed a relative symlink, resolves the target
  # against the working directory instead of the link's -- so a linked `wender` ran in whichever
  # directory the link happened to point out of and nowhere else, dying on a wender.cfg it could not
  # find. An exec script hands it the absolute path it needs. Linux uses one too: the .deb reaches
  # /usr/bin through an absolute symlink and says nothing about how the launcher treats a relative
  # one, and there is no reason to find out from a user's bug report.
  def install
    if OS.mac?
      # jpackage always produces an .app bundle on macOS, even for a console tool. Keeping the
      # bundle intact in libexec and exposing only the launcher gives the usual CLI experience
      # without fighting the packaging format.
      libexec.install "wender.app"
      bin.write_exec_script libexec/"wender.app/Contents/MacOS/wender"
    else
      libexec.install Dir["wender/*"]
      bin.write_exec_script libexec/"bin/wender"
    end
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/wender --version")
  end
end
