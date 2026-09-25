# CRS and vertical-datum conventions

survey-3d is deliberately strict here: **both DEMs must share the same
CRS and the same vertical datum**, or differencing is refused. A metre in
NAVD88 is not a metre in a local site datum, and mixing them produces
volumes that are precisely wrong. The strictness is the feature.

## What the engine assumes

- Horizontal and vertical units are **metres**.
- Both DEMs are in the **same projected or geographic CRS** (checked by
  `acquire.check_crs_match()` for files, `diff.check_grids()` for arrays).
- Both DEMs share the **same vertical datum** (e.g. both NAVD88, both
  EGM2008, or both a consistent local site datum). The engine cannot
  verify this from raster metadata alone — **the operator asserts it**.
- No datum transformation is ever performed inside the engine. If your
  DEMs disagree, convert them first (GDAL, survey-geodesy's datum tools,
  or your survey software) and difference the converted products.

## DSM vs DTM — do not mix silently

- **DSM** (digital *surface* model): includes trees, buildings, stockpiles.
- **DTM** (digital *terrain* model): bare earth.

Difference DSM−DSM for surface change (construction progress, canopy
growth), DTM−DTM for bare-earth change (cut/fill quantities). Differencing
a DSM against a DTM confounds vegetation with earthwork — a cleared
forest reads as a 15 m "cut". If you must compare across types, say so
in your report and treat the numbers as surface change, not quantities.

## Practical guidance

| DEM source | Typical vertical accuracy | Sensible noise floor |
|---|---|---|
| UAV photogrammetry (GCP-controlled) | 0.03–0.10 m | 0.05–0.15 m |
| Airborne LiDAR | 0.05–0.15 m | 0.10–0.20 m |
| Satellite stereo (e.g. 0.5 m imagery) | 0.5–2 m | 1–3 m |
| Global DEMs (SRTM/ALOS/Copernicus) | 2–10 m | 5–15 m |

The noise floor should reflect the DEMs' *actual* vertical accuracy, not
the precision you wish they had. When in doubt, difference two DEMs of
the *same* epoch (or the stable-area check) and set the floor above the
observed stable-ground spread.
