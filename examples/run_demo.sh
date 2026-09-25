#!/usr/bin/env bash
# Full survey-3d pipeline on the seeded synthetic site (no data files needed).
set -euo pipefail
survey-3d coreg --synthetic
survey-3d diff --synthetic --noise-floor 0.08
survey-3d volumes --synthetic --noise-floor 0.08 --rmse1 0.03 --rmse2 0.03 --out volumes.csv
survey-3d polygons --synthetic --threshold 0.08 --out change_polygons.geojson
