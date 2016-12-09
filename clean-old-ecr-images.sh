#!/bin/bash

# Script to clean ECR repos

# TODO: paramertirize further to set the retention period.

## Usage:
## ./clean-old-ecr-images.sh <IMAGE-REPO-NAME> <WEEKS-TO-KEEP>

## Dependencies
## Requires jq and aws command line
## aws credentials are also needed to access the repo. These can be set up using the "aws configure" command.
## A default region will be required.

# Check if jq is available
type jq >/dev/null 2>&1 || { echo >&2 "The jq utility is required for this script to run."; exit 1; }

# Check if aws cli is available
type aws >/dev/null 2>&1 || { echo >&2 "The aws cli is required for this script to run."; exit 1; }

# Check number of arguments parsed
if [ $# -ne 2 ]; then
        echo "Useage ./clean-old-ecr-images.sh <IMAGE-REPO-NAME> <WEEKS-TO-KEEP>"
        exit 1
fi

REPO=$1
WEEKS=$2
SECONDS=$(echo "$WEEKS * 604800" | bc)

read -p "Delete images older than $WEEKS weeks from $REPO (y/n)? " CHOICE

case "$CHOICE" in
  y|Y)
    WEEKS_AGO=$(echo "$(date +%s)-$SECONDS" | bc)
    IMAGES=$(aws ecr describe-images --repository-name $REPO --output json | jq '.[]' | jq '.[]' | jq "select (.imagePushedAt < $WEEKS_AGO)" | jq -r '.imageDigest')
    for IMAGE in ${IMAGES[*]}; do
      echo "Deleting $IMAGE"
      aws ecr batch-delete-image --repository-name $REPO --image-ids imageDigest=$IMAGE
    done
  ;;

  *) exit 0  ;;
esac


