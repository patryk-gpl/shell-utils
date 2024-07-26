aws_ecr_get_repositories_by_prefix() {
  local prefix="$1"

  if [[ -z "$prefix" ]]; then
    echo "Usage: aws_ecr_get_repositories_by_prefix <prefix>"
    return 1
  fi

  aws ecr describe-repositories | jq -r '.repositories[] | select(.repositoryName | startswith("'"$prefix"'")) | .repositoryName' | sort
}
