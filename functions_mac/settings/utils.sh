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
