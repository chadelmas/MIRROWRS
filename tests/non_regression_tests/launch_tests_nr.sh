#!/bin/bash
# Copyright (C) 2024-2026 CS GROUP, https://csgroup.eu
#
# This file is part of MIRROWRS (Mapper to InfeR River Observations of Widths from Remote Sensing)
#
#     https://github.com/csgroup-oss/MIRROWRS
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

echo
echo "===== Launch non regression tests ====="
echo

# Generate non regression tests outputs
jobid=$(sbatch --account=campus mirrowrs_tests_nr.slurm | awk '{print $4}')
echo "Job in process...: $jobid"

while squeue -j $jobid 2>/dev/null | grep -q $jobid; do
  sleep 10
done

# Analyse outputs
echo -e "\n===== Analyse tests ====="
./analyse_tests_nr.sh

# Open dashboard
DASH="/work/CAMPUS/etudes/hydro_aval/BAS/tests_non_regression/dashboard.html"

echo -e "\n===== Results ====="
if [ -f "$DASH" ]; then
  echo "Opening dashboard..."
  xdg-open "$DASH" >/dev/null 2>&1 &
else
  echo "!! Dashboard not find"
fi


