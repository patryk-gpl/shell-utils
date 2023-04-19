#!/bin/bash -e
#
# Common utility functions

function eLog() {
  echo
  echo "== $(date +'%Y-%m-%d %H:%M:%S') $@ ==" | tee -a $LOG_OUT
}

function eLogShort() {
  echo "  => $@" | tee -a $LOG_OUT
}

function printHeaderAndFooter() {
  printf "\n"
  printf '=%.0s' {1..50}
  printf "\n"
  eval $@
  printf "=%.0s" {1..50}
  printf "\n"
}

function _ssh_check_key_checksum() {
  algorithm=$1
  key=$2

  echo "Checking $algorithm fingerprint of key $key"
  ssh-keygen -E $algorithm -lf $key
}

function ssh_check_key_md5() {
  key=${1:-~/.ssh/id_rsa}
  _ssh_check_key_checksum md5 $key
}

function ssh_check_key() {
  key=${1:-~/.ssh/id_rsa}
  _ssh_check_key_checksum sha256 $key
}
alias ssh_check_key_sha256="ssh_check_key $@"
