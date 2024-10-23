# Retrieves metadata from AWS EC2 instance.
# This function fetches various metadata information from the AWS EC2 instance
# it is running on. The metadata can include instance ID, instance type,
# availability zone, and other details provided by the AWS EC2 metadata service.
#
# Usage:
#   aws_ec2_get_metadata
#
# Example:
#   metadata=$(aws_ec2_get_metadata)
#   echo "$metadata"
aws_ec2_get_metadata() {
  local output_format="formatted"
  local show_help=0

  show_usage() {
    echo "Usage: aws_ec2_get_metadata [-o|--original] [-f|--formatted] [-h|--help]"
    echo
    echo "Options:"
    echo "  -o, --original   Output all metadata in original, unmodified format"
    echo "  -f, --formatted  Output metadata in a human-readable format (default)"
    echo "  -h, --help       Show this help message"
    echo
    echo "If no option is provided, the formatted output will be displayed."
  }

  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -o | --original) output_format="original" ;;
      -f | --formatted) output_format="formatted" ;;
      -h | --help) show_help=1 ;;
      *)
        echo "Unknown option: $1" >&2
        sh
        ;;
    esac
    shift
  done

  if [ $show_help -eq 1 ]; then
    show_usage
    return 0
  fi

  get_metadata() {
    local path=$1
    curl -s -f -H "X-aws-ec2-metadata-token: $TOKEN" "http://169.254.169.254/latest/meta-data/$path"
  }

  TOKEN=$(curl -s -f -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

  if [ -z "$TOKEN" ]; then
    echo "Failed to obtain metadata token. Ensure you're running this on an EC2 instance with IMDSv2 enabled." >&2
    return 1
  fi

  if [ "$output_format" = "original" ]; then
    echo "EC2 Instance Metadata (Original Format):"
    echo "========================================"

    for item in $(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" "http://169.254.169.254/latest/meta-data/"); do
      echo -n "$item: "
      curl -s -H "X-aws-ec2-metadata-token: $TOKEN" "http://169.254.169.254/latest/meta-data/$item"
      echo
    done

    echo "User Data:"
    curl -s -f -H "X-aws-ec2-metadata-token: $TOKEN" "http://169.254.169.254/latest/user-data" || echo "No user data available"
  else
    echo "EC2 Instance Metadata:"
    echo "======================"
    echo "Instance ID: $(get_metadata instance-id)"
    echo "AMI ID: $(get_metadata ami-id)"
    echo "Instance Type: $(get_metadata instance-type)"
    echo "Hostname: $(get_metadata hostname)"
    echo "Local IP: $(get_metadata local-ipv4)"
    PUBLIC_IP=$(get_metadata public-ipv4)
    if [ -n "$PUBLIC_IP" ]; then
      echo "Public IP: $PUBLIC_IP"
    else
      echo "Public IP: Not assigned"
    fi
    echo "Availability Zone: $(get_metadata placement/availability-zone)"
    echo "Region: $(get_metadata placement/region)"
    IAM_ROLE=$(get_metadata iam/security-credentials/)
    if [ -n "$IAM_ROLE" ]; then
      echo "IAM Role: $IAM_ROLE"
      echo "IAM Credentials:"
      get_metadata "iam/security-credentials/$IAM_ROLE" | jq '.'
    else
      echo "IAM Role: Not assigned"
    fi
    echo "MAC Address: $(get_metadata mac)"
    echo "Network Interfaces:"
    for mac in $(get_metadata network/interfaces/macs/); do
      mac=${mac%/}
      echo "  Interface with MAC $mac:"
      echo "    VPC ID: $(get_metadata "network/interfaces/macs/${mac}/vpc-id")"
      echo "    Subnet ID: $(get_metadata "network/interfaces/macs/${mac}/subnet-id")"
    done
    echo "User Data:"
    USER_DATA=$(curl -s -f -H "X-aws-ec2-metadata-token: $TOKEN" "http://169.254.169.254/latest/user-data")
    if [ -n "$USER_DATA" ]; then
      echo "$USER_DATA"
    else
      echo "  No user data found or not accessible"
    fi
  fi
}
