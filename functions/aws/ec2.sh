#!/usr/bin/env bash
####################################################################################################
# This file contains functions to work with AWS EC2
####################################################################################################

aws_ec2_status() {
  local instance_id="$1"

  if [[ -z "$instance_id" ]]; then
    echo "Usage: aws_ec2_status <instance_id>"
    return 1
  fi

  echo "State of the AWS EC2 instance $instance_id before reboot:"
  aws ec2 describe-instances --instance-ids  $instance_id --query 'Reservations[].Instances[].{Name: Tags[?Key==`Name`].Value | [0], State: State.Name}' | jq .
}

aws_ec2_restart_instance() {
  local instance_id="$1"

  aws_ec2_status "$instance_id" || return $?

  echo "Do you want to reboot the AWS EC2 instance $instance_id? (y/n)"
  read -r answer
  if [[ "$answer" != "y" ]]; then
      echo "The AWS EC2 instance $instance_id was not rebooted."
      return 0
  else
      echo "Rebooting the AWS EC2 instance $instance_id..."
      aws ec2 reboot-instances --instance-ids "$instance_id" | jq .
  fi
}

aws_ec2_start(){
  local instance_id="$1"

  if [[ -z "$instance_id" ]]; then
    echo "Usage: aws_ec2_start <instance_id>"
    return 1
  fi

  echo "Starting the AWS EC2 instance $instance_id..."
  aws ec2 start-instances --instance-ids "$instance_id" | jq .
}

aws_ec2_stop(){
  local instance_id="$1"

  if [[ -z "$instance_id" ]]; then
    echo "Usage: aws_ec2_stop <instance_id>"
    return 1
  fi

  echo "Stopping the AWS EC2 instance $instance_id..."
  aws ec2 stop-instances --instance-ids "$instance_id" | jq .
}