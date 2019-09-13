#!/bin/bash
#
# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -eox pipefail

[[ -z "$NAME" ]] && echo "NAME must be set" && exit 1
[[ -z "$NAMESPACE" ]] && echo "NAMESPACE must be set" && exit 1

echo "Creating the manifests for the kubernetes resources that install \"$NAME\""

data_dir="/data"
manifest_dir="$data_dir/manifest-expanded"
mkdir "$manifest_dir"
manifest_ingress_dir="$data_dir/manifest-ingress-expanded"
mkdir "$manifest_ingress_dir"

# Store environment variables in local variable
env_vars="$(/bin/print_config.py -o shell_vars)"

# Merge CloudBees Core manifest with environment variables
for manifest in "$data_dir"/manifest/*; do
  manifest_file=$(basename "$manifest" | sed 's/.template$//')
  cat "$manifest" \
    | /bin/config_env.py envsubst "${env_vars}" \
    > "$manifest_dir/$manifest_file"
done

# Merge Nginx ingress manifest with environment variables
for manifest in "$data_dir"/manifest-ingress/*; do
  manifest_file=$(basename "$manifest" | sed 's/.template$//')
  cat "$manifest" \
    | /bin/config_env.py envsubst "${env_vars}" \
    > "$manifest_ingress_dir/$manifest_file"
done