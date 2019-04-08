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

function reset_terminal() {
 stty sane
 tput rs1
}
