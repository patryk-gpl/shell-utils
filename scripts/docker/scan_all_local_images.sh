#!/usr/bin/env bash

images=$(docker images --format "{{.Repository}}:{{.Tag}}")

for image in $images; do
  filename=${image//\//_}
  echo "Checking CVEs for image: $image. Save report to $filename.cve"
  docker scout cves "$image" >"$filename.cve"
done
