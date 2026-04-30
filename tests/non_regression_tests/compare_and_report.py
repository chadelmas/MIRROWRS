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


"""
Compare and report non regression tests
: module for tests_nr.sh
"""

import sys
import json
from pathlib import Path
import pandas as pd
from deepdiff import DeepDiff
from jinja2 import Template
from datetime import datetime

# pip install deepdiff jinja2 --index-url https://pypi.org/simple


def compare_csv(file1, file2, tol=1e-6):
    import pandas as pd

    df1 = pd.read_csv(file1)
    df2 = pd.read_csv(file2)

    if df1.shape != df2.shape:
        return False, "Shape mismatch", None

    def highlight(row):
        row2 = df2.loc[row.name]
        out = []

        for a, b in zip(row, row2):
            if pd.isna(a) and pd.isna(b):
                out.append("")
            elif isinstance(a, (int, float)) and isinstance(b, (int, float)):
                out.append("background-color:red" if abs(a-b) > tol else "")
            else:
                out.append("background-color:red" if a != b else "")

        return out

    styled = df1.style.apply(highlight, axis=1)
    html = styled.to_html()

    # Test global
    if df1.equals(df2):
        return True, "OK", html

    return False, "Diff detected", html


def compare_json(file1, file2):
    with open(file1) as f:
        j1 = json.load(f)
    with open(file2) as f:
        j2 = json.load(f)

    diff = DeepDiff(j1, j2, ignore_order=True)

    if diff:
        return False, diff.to_json(indent=2)
    return True, "OK"


def generate_html(results, output_file):
    template = Template("""
    <html>
    <head>
        <style>
            body { font-family: Arial; }
            .ok { color: green; }
            .ko { color: red; }
            table { border-collapse: collapse; }
            td, th { border: 1px solid #ccc; padding: 4px; }
        </style>
    </head>
    <body>
        <h1>Non Regression Report</h1>
        <p>Date: {{ date }}</p>

        {% for r in results %}
            <h2>{{ r.file }}</h2>

            {% if r.ok %}
                <p class="ok">OK</p>
            {% else %}
                <p class="ko">KO</p>
                <pre>{{ r.msg }}</pre>
            {% endif %}

            {% if r.table %}
                {{ r.table | safe }}
            {% endif %}
        {% endfor %}
    </body>
    </html>
    """)


    html = template.render(
        results=results,
        date=datetime.now()
    )

    with open(output_file, "w") as f:
        f.write(html)


def main(out_dir, ref_dir, report_file):
    out_dir = Path(out_dir)
    ref_dir = Path(ref_dir)

    results = []
    fail = False

    for ref_file in ref_dir.rglob("*"):
        if not ref_file.is_file():
            continue

        rel = ref_file.relative_to(ref_dir)
        out_file = out_dir / rel

        if not out_file.exists():
            results.append({
                "file": str(rel),
                "ok": False,
                "msg": "Missing"
            })
            fail = True
            continue

        if ref_file.suffix == ".csv":
            ok, msg, _ = compare_csv(out_file, ref_file)
        elif ref_file.suffix == ".json":
            ok, msg = compare_json(out_file, ref_file)
        else:
            continue

        if not ok:
            fail = True

        results.append({
            "file": str(rel),
            "ok": ok,
            "msg": msg
        })

    generate_html(results, report_file)

    if fail:
        sys.exit(1)
    else:
        sys.exit(0)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3])
