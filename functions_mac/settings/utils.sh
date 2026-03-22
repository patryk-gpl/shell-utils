mac_profile_status() {
  echo "Checking System Integrity Protection status..."
  csrutil status
  echo "Checking for enrollment type..."
  profiles status -type enrollment
  echo "Checking for existing profiles..."
  profiles -L
  echo "List MDM profiles.."
  profiles list
  echo "Checking for configuration profile..."
  profiles show -type configuration
}

mac_users_with_secure_token() {
  echo "Checking for users with Secure Token..."
  for u in $(dscl . list /Users)
  do
    sysadminctl -secureTokenStatus "$u" 2>&1 | grep -E "for user|ENABLED|DISABLED"
  done | grep ENABLED
}

mac_user_password_reset() {
  local username="$1"
  local new_password="$2"

  if [[ -z "$username" ]] || [[ -z "$new_password" ]]; then
    echo "Usage: mac_user_password_reset <username> <new_password>"
    return 1
  fi

  echo "Resetting password for user: $username"
  sysadminctl -resetPasswordFor "$username" -newPassword "$new_password"
}
