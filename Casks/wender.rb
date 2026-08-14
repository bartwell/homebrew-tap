cask "wender" do
  version "6.6.11"
  sha256 "e0858669bf103153a2d79dec2a22f2c0bc1f685cd561cc82d1f35552d6b3ad81"

  url "https://github.com/bartwell/wender-cli/releases/download/v6.6.11/wender-#{version}-macos-arm64.tar.gz"
  name "Wender CLI"
  desc "Transfer files and directories between devices over WiFi"
  homepage "https://github.com/bartwell/wender-cli"

  # A cask rather than a formula, even though this is a command-line tool and nothing here has a
  # window. Installing a formula runs Keg#fix_dynamic_linkage over the whole keg: it rewrites the
  # dylib id of every Mach-O it finds -- including the thirteen inside the bundled Java runtime --
  # and re-signs each one ad-hoc, because the rewrite invalidates whatever signature was there.
  # That is fatal for a bundle carrying a Developer ID signature: the seal no longer covers its own
  # files and the kernel kills the launcher at exec, with the Finder alert about a damaged
  # application. A cask copies the artifact and leaves it alone, so the signature and the
  # notarization ticket reach the user intact. There is no formula option that turns the rewriting
  # off; shipping a formula would mean shipping an unsigned archive on purpose.
  #
  # Apple Silicon only: GitHub retired the Intel macOS runners, and an arm64 build cannot serve an
  # Intel Mac -- Rosetta translates x86 to arm, not the reverse.
  depends_on arch: :arm64
  # The bundled runtime is built against the macOS 11 SDK. A bare symbol is the cask spelling of
  # "this version or newer"; the string form is deprecated.
  depends_on macos: :big_sur

  # jpackage always produces an .app bundle on macOS, even for a console tool, so the launcher
  # arrives inside one. `binary` puts it on PATH and leaves the bundle in the Caskroom, which gives
  # the usual CLI experience without unpacking anything: `app` would only move the same bundle into
  # /Applications, where a program with no interface has no business being.
  #
  # The symlink Homebrew writes for a cask is absolute, and that matters: a jpackage launcher works
  # out where its runtime lives from its own argv[0], and handed a relative symlink it resolves the
  # target against the working directory instead of the link's, then dies on a wender.cfg it cannot
  # find.
  binary "wender-#{version}/wender.app/Contents/MacOS/wender"

  # Homebrew marks what a cask downloads with com.apple.quarantine, and the first launch of a
  # quarantined bundle puts a Gatekeeper consent dialog in front of whoever runs it. For something
  # invoked by typing `wender` in a terminal that is startling at best, and over SSH or in a script
  # there is no dialog to answer at all -- the process simply waits. That is not hypothetical: the
  # release check for 6.6.11 sat on exactly that prompt for two and a half hours.
  #
  # Removing the attribute gives up nothing that was protecting anyone. Homebrew has already checked
  # the download against the sha256 above, the bundle is Developer ID signed, notarized and stapled,
  # and the release refuses to publish a cask whose bundle does not pass `spctl --assess` -- so the
  # verdict the dialog would ask about has been obtained already, without a human in the loop.
  postflight do
    system_command "/usr/bin/xattr",
                   args:         ["-r", "-d", "com.apple.quarantine", staged_path/"wender-#{version}/wender.app"],
                   # The attribute is absent often enough -- a local file:// install, a machine where
                   # quarantine is switched off -- and xattr treats that as an error.
                   must_succeed: false
  end
end
