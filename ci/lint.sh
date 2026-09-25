#!/usr/bin/env bash
#
# Copyright 2026 The OKDP Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Lints the charts of this repository, the same way in CI and on a laptop.
# Needs helm, chart-testing (ct) and yamllint. Run it from anywhere:
#
#   ci/lint.sh
#
# 1. yamllint on every Chart.yaml and values file under modules/, with the
#    rules of .lintconf.yaml
# 2. chart-testing lint on every chart under modules/ (helm dependency build,
#    helm lint with each ci/*-values.yaml), with the repositories of .ct.yml
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> yamllint"
find modules -mindepth 2 -maxdepth 3 \
  \( -name Chart.yaml -o -name 'values*.yaml' -o -name '*-values.yaml' \) -print0 \
  | sort -z | xargs -0 yamllint -c .lintconf.yaml
echo "yamllint: ok"

echo "==> chart-testing lint"
ct lint --config .ct.yml --check-version-increment=false --all
