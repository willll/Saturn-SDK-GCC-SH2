#!/bin/bash

# Source common utilities
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

trace_info "Starting branch merge process..."

branches=()
eval "$(redirect_output git for-each-ref --shell --format='branches+=(%(refname))' refs/heads/)"

for branch in "${branches[@]}"; do
    if [[ $branch == *"gcc_"* ]]; then
        trace_info "Processing branch: $branch"
        redirect_output git checkout "$branch" || {
            trace_error "Failed to checkout branch: $branch"
            continue
        }
        
        redirect_output git cherry-pick -x 70412a3f642c657c61d891d45f46927ce268454e || {
            trace_error "Failed to cherry-pick commit into branch: $branch"
            redirect_output git cherry-pick --abort
            continue
        }
        trace_success "Successfully merged commit into branch: $branch"
    fi
done

trace_success "Branch merge process completed"
