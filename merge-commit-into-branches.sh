#!/bin/bash

branches=()
eval "$(git for-each-ref --shell --format='branches+=(%(refname))' refs/heads/)"
for branch in "${branches[@]}"; do
    if [[ $branch == *"gcc_"* ]]; then
        echo $branch
	git checkout $branch
	git cherry-pick -x 70412a3f642c657c61d891d45f46927ce268454e
    fi
done
