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


BASE="/work/CAMPUS/etudes/hydro_aval/BAS/tests_non_regression"

FAIL=0

# =========================
# DASHBOARD GLOBAL
# =========================
DASH_FILE="$BASE/dashboard.html"

OK=0
KO=0

echo "<html><head><style>
body { font-family: Arial; }
table { border-collapse: collapse; width: 100%; }
td, th { border: 1px solid #ccc; padding: 6px; }
.ok { background-color: #c8f7c5; }
.ko { background-color: #f7c5c5; }
.zone { background-color: #eee; font-size: 20px; padding: 10px; }
</style></head><body>" > $DASH_FILE

echo "<h1>MIRROWRS - Dashboard NR tests</h1>" >> $DASH_FILE


# =========================
# LOOP ZONES
# =========================
for zone in Garonne Maroni Inde
do
  echo -e "\n== ZONE: $zone"

  echo "<div class='zone'>ZONE: $zone</div>" >> $DASH_FILE
  echo "<table>" >> $DASH_FILE
  echo "<tr><th>Dataset</th><th>CSV</th><th>GeoJSON</th><th>Report link</th></tr>" >> $DASH_FILE


  # =========================
  # LOOP DATASETS
  # =========================
  for out_dir in $(find $BASE/$zone/out -mindepth 2 -maxdepth 2 -type d)
  do
    rel=${out_dir#*$zone/out/}
    ref_dir="$BASE/$zone/ref/$rel"
    report="$out_dir/report.html"
    report_rel="${report#$BASE/}"

    echo "Test: $rel"

    if [ ! -d "$ref_dir" ]; then
      echo "!! Ref missing: $ref_dir"
      FAIL=1

      echo "<tr class='ko'>
        <td>$rel</td>
        <td>❌</td>
        <td>❌</td>
        <td>NO REF</td>
      </tr>" >> $DASH_FILE

      continue
    fi


    # =========================
    # EXEC TEST PYTHON
    # =========================
    python compare_and_report.py "$out_dir" "$ref_dir" "$report"
    status=$?


    # =========================
    # STATUT GLOBAL
    # =========================
    if [ $status -ne 0 ]; then
      FAIL=1
      KO=$((KO+1))

      echo "<tr class='ko'>
        <td>$rel</td>
        <td>❌</td>
        <td>❌</td>
        <td><a href='$report_rel'>report</a></td>
      </tr>" >> $DASH_FILE

    else
      OK=$((OK+1))

      echo "<tr class='ok'>
        <td>$rel</td>
        <td>✅</td>
        <td>✅</td>
        <td><a href='$report_rel'>report</a></td>
      </tr>" >> $DASH_FILE
    fi

  done


  echo "</table><br>" >> $DASH_FILE
done

# Final status
if [ $FAIL -ne 0 ]; then
  echo "<h2 style='color:red'>NON REGRESSION TESTS FAILED</h2>" >> $DASH_FILE
else
  echo "<h2 style='color:green'>NON REGRESSION TESTS OK</h2>" >> $DASH_FILE
fi


echo "</body></html>" >> $DASH_FILE


# =========================
# EXIT STATUS
# =========================
if [ $FAIL -ne 0 ]; then
  echo -e "\n================================="
  echo "==== NON REGRESSION TESTS KO ===="
  echo "================================="
  exit 1
else
  echo -e "\n================================="
  echo "==== NON REGRESSION TESTS OK ===="
  echo "================================="
fi
