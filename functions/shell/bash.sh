bash_reset_history_and_logs() {
  echo "Clearing Bash history..."
  history -c
  rm -f ~/.bash_history
  touch ~/.bash_history

  echo "Reloading the history.."
  history -r

  if [ -f ~/.lesshst ]; then
    echo "Clearing .lesshst file..."
    rm -f ~/.lesshst
  fi
  if [ -f ~/.viminfo ]; then
    echo "Clearing .viminfo file..."
    rm -f ~/.viminfo
  fi

  echo "History and logs have been cleared."
  echo "History has been reloaded in the current session."
  echo "For complete effect on all terminals, you may want to log out and log back in."
}
