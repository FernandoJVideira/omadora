# Offer a GitHub login so git push over https works (gh is the credential helper for github.com).
# Skipped when gh is missing, already logged in, or there is no terminal to ask on. Never fails the install.

if command -v gh >/dev/null && ! gh auth status >/dev/null 2>&1 && [[ -r /dev/tty && -w /dev/tty ]]; then
  # install.sh pipes its output through tee, so gh would not see a terminal: talk to /dev/tty directly
  if gum confirm "Log in to GitHub now? (lets you push to your repos)" </dev/tty >/dev/tty 2>&1; then
    if gh auth login --hostname github.com --git-protocol https --web </dev/tty >/dev/tty 2>&1; then
      gh auth setup-git --hostname github.com || true
    else
      echo "GitHub login did not finish. Run 'gh auth login' later to try again."
    fi
  else
    echo "Skipped GitHub login. Run 'gh auth login' whenever you want it."
  fi
fi
