#!/bin/bash

PATTERN_DIR="$1"

if [ -z "$PATTERN_DIR" ]; then
    PATTERN_DIR="."
fi

CGNAME=$(yq '.main.clusterGroupName' "$PATTERN_DIR/values-global.yaml")

if [ -n "$TARGET_SITE" ] && [ -f "$PATTERN_DIR/values-$TARGET_SITE.yaml" ]; then
  CGNAME=$(yq '.clusterGroup.name' "$PATTERN_DIR/values-$TARGET_SITE.yaml")
fi

if [ -z "$CGNAME" ] || [ "$CGNAME" == "null" ]; then
    echo "Error - cannot determine clusterGroupName"
    exit 1
fi

echo "$CGNAME"
