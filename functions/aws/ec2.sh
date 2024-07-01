#!/usr/bin/env bash
# Functions to work with AWS EC2

aws_ec2_regions_list() {
  aws ec2 describe-regions --query 'Regions[].RegionName' --output text
}

aws_ec2_status() {
  local instance_ids=("$@")

  if [[ ${#instance_ids[@]} -eq 0 ]]; then
    echo "Usage: aws_ec2_status <instance_id> [<instance_id> ...]"
    return 1
  fi

  echo "State of the AWS EC2 instances:" "${instance_ids[@]}"
  aws ec2 describe-instances --instance-ids "${instance_ids[@]}" \
    --query 'Reservations[].Instances[].{Name: Tags[?Key=="Name"].Value | [0], State: State.Name}' --output table
}

aws_ec2_start() {
  local instance_ids=("$@")

  if [[ ${#instance_ids[@]} -eq 0 ]]; then
    echo "Usage: aws_ec2_start <instance_id> [<instance_id> ...]"
    return 1
  fi

  echo "Starting the AWS EC2 instances:" "${instance_ids[@]}"
  aws ec2 start-instances --instance-ids "${instance_ids[@]}" --output json | jq .
}

aws_ec2_stop() {
  local instance_ids=("$@")

  if [[ ${#instance_ids[@]} -eq 0 ]]; then
    echo "Usage: aws_ec2_stop <instance_id> [<instance_id> ...]"
    return 1
  fi

  echo "Stopping the AWS EC2 instances:" "${instance_ids[@]}"
  aws ec2 stop-instances --instance-ids "${instance_ids[@]}" --output json | jq .
}

aws_ec2_restart_instance() {
  local instance_id="$1"
  if [[ -z "$instance_id" ]]; then
    echo "Usage: aws_ec2_restart_instance <instance_id>"
    return 1
  fi

  state=$(aws ec2 describe-instances --instance-ids "$instance_id" \
    --query 'Reservations[].Instances[].State.Name' --output text)

  if [[ "$state" == "running" ]]; then
    echo "Do you want to reboot the AWS EC2 instance $instance_id? (y/n)"
    read -r answer
    if [[ "$answer" != "y" ]]; then
      echo "The AWS EC2 instance $instance_id was not rebooted."
      return 0
    else
      aws ec2 reboot-instances --instance-ids "$instance_id" | jq .
    fi
  else
    echo "The AWS EC2 instance $instance_id is not running. Do you want to start it? (y/n)"
    read -r answer
    if [[ "$answer" != "y" ]]; then
      echo "The AWS EC2 instance $instance_id was not started."
      return 0
    fi
    aws_ec2_start "$instance_id"
  fi
}

aws_ec2_get_instance_id_by_ip() {
  local ip_address="$1"

  if [[ -z "$ip_address" ]]; then
    echo "Usage: aws_ec2_get_instance_id_by_ip_address <ip_address>"
    return 1
  fi

  echo "Looking for an instance with private IP address: $ip_address"
  instance_id=$(aws ec2 describe-instances --filters "Name=private-ip-address,Values=$ip_address" --query "Reservations[*].Instances[*].InstanceId" --output text)

  if [[ -z "$instance_id" || "$instance_id" == "None" ]]; then
    echo "No instance found with private IP address: $ip_address"
    echo "Looking for an instance with public IP address: $ip_address"
    instance_id=$(aws ec2 describe-instances --filters "Name=ip-address,Values=$ip_address" --query "Reservations[*].Instances[*].InstanceId" --output text)
  fi

  if [[ -z "$instance_id" || "$instance_id" == "None" ]]; then
    echo "No instance found with IP address: $ip_address"
    return 1
  else
    echo "Instance ID: $instance_id"
  fi
}

aws_ec2_instance_network_details() {
  local instance_id="$1"

  if [[ -z "$instance_id" ]]; then
    echo "Usage: aws_ec2_instance_network_details <instance_id>"
    return 1
  fi

  aws ec2 describe-instances --instance-ids "$instance_id" \
    --query 'Reservations[].Instances[].{PublicIpAddress: PublicIpAddress, PrivateIpAddress: PrivateIpAddress, SubnetId: SubnetId, VpcId: VpcId, NetworkInterfaces: NetworkInterfaces}'
}
