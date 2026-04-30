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

#"""
#Generate non regression tests products
#"""

#SBATCH --job-name=BAS_test_NR
#SBATCH --output=/work/CAMPUS/etudes/hydro_aval/BAS/tests_non_regression/log/test_%A_%a.out
#SBATCH --error=/work/CAMPUS/etudes/hydro_aval/BAS/tests_non_regression/log/test_%A_%a.err
#SBATCH --array=0-4
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --cpus-per-task=12
#SBATCH --mem-per-cpu=10G
#SBATCH --time=01:00:00
#SBATCH --account=campus

module purge
ml conda
conda activate mirrowrs_env


# CONFIG
# ======

input_files=(
"/work/CAMPUS/etudes/hydro_aval/BAS/tests_non_regression/Garonne/in/SURFWATER_OPTICAL-SINGLE_T31TDJ_20230808T105859_20230808T105859_1-3-1_01.tif"
"/work/CAMPUS/etudes/hydro_aval/BAS/tests_non_regression/Maroni/in/SURFWATER_RADAR-SINGLE_T21NYE_20230106Txxxxxx_20230106Txxxxxx_1.2_000.tif"
"/work/CAMPUS/etudes/hydro_aval/BAS/tests_non_regression/Maroni/in/SURFWATER_RADAR-SINGLE_T21NYE_20230417Txxxxxx_20230417Txxxxxx_1.2_000.tif"
"/work/CAMPUS/etudes/hydro_aval/BAS/tests_non_regression/Inde/in/SURFWATER_OPTICAL-SINGLE_T44QPL_20250320T051250_20250320T051250_1-3-2_01.tif"
"/work/CAMPUS/etudes/hydro_aval/BAS/tests_non_regression/Inde/in/SURFWATER_OPTICAL-SINGLE_T45QVC_20250312T050301_20250312T050301_1-3-2_01.tif"
)

reaches=(
"/work/SWOT/swotdev/swotpub/BD/BD_rivers/SWORD_v16/shp/EU/eu_sword_reaches_hb23_v16.shp"
"/work/SWOT/swotdev/swotpub/BD/BD_rivers/SWORD_v16/shp/SA/sa_sword_reaches_hb61_v16.shp"
"/work/SWOT/swotdev/swotpub/BD/BD_rivers/SWORD_v16/shp/SA/sa_sword_reaches_hb61_v16.shp"
"/work/SWOT/swotdev/swotpub/BD/BD_rivers/SWORD_v16/shp/AS/as_sword_reaches_hb45_v16.shp"
"/work/SWOT/swotdev/swotpub/BD/BD_rivers/SWORD_v16/shp/AS/as_sword_reaches_hb45_v16.shp"
)
#"/work/CAMPUS/etudes/hydro_aval/GNS/BAS/shape_inde/as_sword_reaches_hb45_v16_extractInde.shp"

nodes=(
"/work/SWOT/swotdev/swotpub/BD/BD_rivers/SWORD_v16/shp/EU/eu_sword_nodes_hb23_v16.shp"
"/work/SWOT/swotdev/swotpub/BD/BD_rivers/SWORD_v16/shp/SA/sa_sword_nodes_hb61_v16.shp"
"/work/SWOT/swotdev/swotpub/BD/BD_rivers/SWORD_v16/shp/SA/sa_sword_nodes_hb61_v16.shp"
"/work/SWOT/swotdev/swotpub/BD/BD_rivers/SWORD_v16/shp/AS/as_sword_nodes_hb45_v16.shp"
"/work/SWOT/swotdev/swotpub/BD/BD_rivers/SWORD_v16/shp/AS/as_sword_nodes_hb45_v16.shp"
)
#"/work/CAMPUS/etudes/hydro_aval/GNS/BAS/shape_inde/as_sword_nodes_hb45_v16_extractInde.shp"


zones=("Garonne" "Maroni" "Maroni" "Inde" "Inde")

output_root="/work/CAMPUS/etudes/hydro_aval/BAS/tests_non_regression"


# SELECTION
# =========

i=$SLURM_ARRAY_TASK_ID

zone=${zones[$i]}
input_file=${input_files[$i]}
reach_file=${reaches[$i]}
node_file=${nodes[$i]}

echo "======================================="
echo "JOB  = $SLURM_JOB_ID"
echo "TASK = $SLURM_ARRAY_TASK_ID"
echo "ZONE = $zone"
echo "INPUT = $input_file"
echo "======================================="


# TRAITEMENT
# ==========

if [[ "$input_file" == *.tif ]]; then

    echo "----------"
    echo "Processing $input_file"

    tif_filename=$(basename "$input_file")

    datetime=$(echo "$tif_filename" | grep -oP '\d{8}T[A-Za-z0-9]{6}' | head -n 1)
    tile_name=$(echo "$tif_filename" | sed -E 's/.*(T[0-9]{2}[A-Z]{3}).*/\1/')

    output_dir="$output_root/$zone/out/$tile_name/$datetime"
    mkdir -p "$output_dir"

    echo "Output dir = $output_dir"

    # skip si déjà fait
    if ls "$output_dir"/*.csv 1> /dev/null 2>&1; then
      echo "== Already processed"
      exit 0
    fi

    cmd="run_example \
      -w $input_file \
      -dt $datetime \
      -r $reach_file \
      -n $node_file \
      -o $output_dir \
      -mo"

    echo "$cmd"
    $cmd
    echo "OK"

else
  echo "!! File missing : $input_file"
  exit 1
fi

echo "======================================="
echo "FIN JOB $SLURM_JOB_ID / TASK $SLURM_ARRAY_TASK_ID"
echo "======================================="

