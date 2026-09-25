# Difference-raster and change-polygon spec

## Difference raster

- **Definition:** `diff = dem2 − dem1`, pixelwise, in the DEMs' vertical
  units (metres by convention).
- **Nodata:** NaN where *either* input DEM is NaN. The engine never
  interpolates across nodata.
- **Grid:** identical shape, transform, CRS, and vertical datum for both
  inputs — enforced by `check_grids()` (arrays) and
  `acquire.check_crs_match()` (files). The engine never resamples;
  mismatched grids are an error, not a silent warp.
- **Thresholded product:** `|Δh| < noise_floor → 0` (NaN stays NaN).
  The raw difference is always available alongside; volumetrics use the
  thresholded one.
- **File output:** single-band float32 GeoTIFF (deflate, tiled) + `.qml`
  diverging style (red = cut/negative, blue = fill/positive, white at 0).

## Change polygons (GeoJSON)

Produced by `polygons.change_polygons()` from a difference raster:

1. Threshold `|Δh| ≥ threshold` → binary mask (NaN = not change).
2. 8-connected component labelling (pure numpy).
3. Drop components with fewer than `min_pixels` pixels (speckle filter).
4. Trace each component's boundary by chaining directed pixel edges
   (interior on the left); the largest ring is the exterior, the rest
   are interior holes.
5. Emit GeoJSON `Polygon` features in map coordinates.

Per-feature properties:

| Property | Meaning |
|---|---|
| `cut_m3` | prism-method cut volume inside the feature (m³) |
| `fill_m3` | prism-method fill volume inside the feature (m³) |
| `net_m3` | `fill_m3 − cut_m3` (signed) |
| `dominant` | `"cut"` or `"fill"` (ties → `"fill"`) |
| `area_m2` | planimetric area, holes subtracted (m²) |
| `pixel_count` | component pixel count |

Polygon volumes reconcile with zonal volumes: summing a zone's polygon
`cut_m3`/`fill_m3` approximates the zone's `volumes` output (up to the
speckle filter and the polygon threshold, which may differ from the
volumetric noise floor — document both when comparing).

## Tiling note (large DEMs)

The core algorithms are O(pixels) with small constant factors and
operate on numpy arrays, so they chunk naturally: tile the DEM pair on
a coarse grid with a small overlap (≥ the largest expected change
feature, to avoid splitting polygons), process each tile, and merge
CSV rows by concatenation. Polygon merging across tile boundaries is
*not* implemented in v0.1.0 — keep tiles large relative to features, or
vectorize on the full raster. This is documented as a scaling limit,
not a hidden one.
