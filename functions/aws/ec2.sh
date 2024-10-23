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

aws_ec2_delete() {
  local instance_ids=("$@")

  if [[ ${#instance_ids[@]} -eq 0 ]]; then
    echo "Usage: aws_ec2_delete <instance_id> [<instance_id> ...]"
    return 1
  fi

  echo "Terminating the AWS EC2 instances:" "${instance_ids[@]}"
  aws ec2 terminate-instances --instance-ids "${instance_ids[@]}" --output json | jq .
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

aws_ec2_volume_resize() {
  local instance_id="$1"
  local new_size="$2"

  if [[ -z "$instance_id" || -z "$new_size" ]]; then
    echo "Usage: aws_ec2_volume_resize <instance_id> <new_size_in_GB>"
    return 1
  fi

  # Get the volume ID of the root device
  local volume_id
  volume_id=$(aws ec2 describe-instances --instance-id "$instance_id" \
    --query 'Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId' \
    --output text)

  if [[ -z "$volume_id" ]]; then
    echo "Failed to retrieve volume ID for instance $instance_id"
    return 1
  fi

  local current_size
  current_size=$(aws ec2 describe-volumes --volume-ids "$volume_id" \
    --query 'Volumes[0].Size' \
    --output text)

  if [[ "$new_size" -le "$current_size" ]]; then
    echo "New size must be greater than the current size ($current_size GB)"
    return 1
  fi

  echo "Resizing volume $volume_id from $current_size GB to $new_size GB..."

  # Modify the volume size
  aws ec2 modify-volume --volume-id "$volume_id" --size "$new_size"

  echo "Waiting for volume modification to complete..."
  aws ec2 wait volume-in-use --volume-ids "$volume_id"

  echo "Volume resize initiated. You may need to extend the file system within the instance."
  echo "To extend the file system, connect to the instance and run:"
  echo "sudo growpart /dev/nvme0n1 1"
  echo "sudo xfs_growfs -d /"
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
  local instance_id=""
  local query_private_ip=false
  local query_public_ip=false
  local query_subnet_id=false
  local query_vpc_id=false
  local query_network_interfaces=false

  # Function to display usage
  show_usage() {
    echo "Usage: aws_ec2_instance_network_details --instance-id <instance_id> [OPTIONS]"
    echo "Options:"
    echo "  --private-ip            Query private IP address"
    echo "  --public-ip             Query public IP address"
    echo "  --subnet-id             Query subnet ID"
    echo "  --vpc-id                Query VPC ID"
    echo "  --network-interfaces    Query network interfaces"
    echo "  --all                   Query all details (default if no option is specified)"
  }

  while [[ "$#" -gt 0 ]]; do
    case $1 in
      --instance-id)
        instance_id="$2"
        shift
        ;;
      --private-ip) query_private_ip=true ;;
      --public-ip) query_public_ip=true ;;
      --subnet-id) query_subnet_id=true ;;
      --vpc-id) query_vpc_id=true ;;
      --network-interfaces) query_network_interfaces=true ;;
      --all)
        query_private_ip=true
        query_public_ip=true
        query_subnet_id=true
        query_vpc_id=true
        query_network_interfaces=true
        ;;
      -h | --help)
        show_usage
        return 0
        ;;
      *)
        echo "Unknown parameter passed: $1"
        show_usage
        return 1
        ;;
    esac
    shift
  done

  if [[ -z "$instance_id" ]]; then
    echo "Error: Instance ID is required." >&2
    show_usage
    return 1
  fi

  # If no specific query is requested, query all
  if ! "$query_private_ip" && ! "$query_public_ip" && ! "$query_subnet_id" && ! "$query_vpc_id" && ! "$query_network_interfaces"; then
    query_private_ip=true
    query_public_ip=true
    query_subnet_id=true
    query_vpc_id=true
    query_network_interfaces=true
  fi

  # Construct the query string
  local query_parts=()
  if "$query_private_ip"; then query_parts+=("PrivateIpAddress: PrivateIpAddress"); fi
  if "$query_public_ip"; then query_parts+=("PublicIpAddress: PublicIpAddress"); fi
  if "$query_subnet_id"; then query_parts+=("SubnetId: SubnetId"); fi
  if "$query_vpc_id"; then query_parts+=("VpcId: VpcId"); fi
  if "$query_network_interfaces"; then query_parts+=("NetworkInterfaces: NetworkInterfaces"); fi

  local query_string
  query_string=$(
    IFS=,
    echo "${query_parts[*]}"
  )

  aws ec2 describe-instances --instance-ids "$instance_id" \
    --query "Reservations[].Instances[].{$query_string}" \
    --output json
}

aws_ec2_instance_get_size() {
  if [ "$#" -ne 1 ]; then
    echo "Usage: aws_ec2_instance_get_size <Instance-ID>" >&2
    return 1
  fi

  local instance_id="$1"

  if [[ -z "$instance_id" ]]; then
    echo "Error: Instance ID is required." >&2
    return 1
  fi

  echo "Fetching details for instance ID: $instance_id..."
  local instance_details
  if ! instance_details=$(aws ec2 describe-instances --instance-ids "$instance_id" --query "Reservations[*].Instances[*].{InstanceType:InstanceType,State:State.Name,LaunchTime:LaunchTime,AvailabilityZone:Placement.AvailabilityZone}" --output json); then
    echo "Failed to fetch instance details. Please check the instance ID." >&2
    return 1
  fi

  echo "Instance details:"
  echo "$instance_details"
}

aws_ec2_instance_change_size() {
  if [ "$#" -ne 2 ]; then
    echo "Usage: aws_ec2_instance_change_size <instance_id> <new_instance_type>" >&2
    return 1
  fi
  local instance_id="$1"
  local new_size="$2"
  if ! [[ "$instance_id" =~ ^i-[0-9a-f]{8,17}$ ]]; then
    echo "Invalid instance ID format: $instance_id" >&2
    return 1
  fi

  local current_type
  current_type=$(aws ec2 describe-instances --instance-ids "$instance_id" --query "Reservations[].Instances[].InstanceType" --output text)
  if [[ "$current_type" == "$new_size" ]]; then
    echo "The new instance type ($new_size) is the same as the current instance type ($current_type)" >&2
    return 1
  fi
  echo "Stopping instance $instance_id..."
  aws ec2 stop-instances --instance-ids "$instance_id"
  aws ec2 wait instance-stopped --instance-ids "$instance_id"

  echo "Changing instance type from $current_type to $new_size..."
  aws ec2 modify-instance-attribute --instance-id "$instance_id" --instance-type "{\"Value\": \"$new_size\"}"

  echo "Starting instance $instance_id..."
  aws ec2 start-instances --instance-ids "$instance_id"
  aws ec2 wait instance-running --instance-ids "$instance_id"

  echo "Instance $instance_id has been resized to $new_size successfully."
}
