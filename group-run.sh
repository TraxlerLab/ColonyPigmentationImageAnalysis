#!/bin/bash

ALL_GROUPS="delta6944 deltaA8 deltaB8 deltaC8 deltaD8 deltaGAF WT"

for group in $ALL_GROUPS; do
    output_dir="grouped-output/$group/"
    mkdir -p "$output_dir"
    echo "Running $group..."
    ./run --output-path "$output_dir" --images "images/$group-*" --baseline-pigmentation 0.3426845566887504 --baseline-pigmentation-histogram-file-path ../baseline-wt-pigmentation.csv
done
