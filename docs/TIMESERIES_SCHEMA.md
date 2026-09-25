# Volume time-series schema

`volumes.csv` — one row per (zone, DEM pair). Appended incrementally;
re-appending the same records is a no-op (dedupe on
`zone_id` + `pass_id` + `index`). The first 17 columns mirror the sibling
analytics engines (survey-vegetation, survey-flood, survey-burn,
survey-coast, survey-thermal); the rest are survey-3d's volumetric
extensions. Append-only: new columns go at the end.

| Column | Type | Meaning |
|---|---|---|
| `zone_id` | string | zone id from the zones GeoJSON |
| `zone_name` | string | human-readable zone name |
| `pass_id` | string | DEM-pair id, e.g. `dem-2024_vs_dem-2025` |
| `date` | string | ISO date (YYYY-MM-DD) of the *later* DEM |
| `doy` | int | day of year of `date` |
| `year` | int | year of `date` |
| `index` | string | always `"dem-diff"` |
| `mean` | float | **mean Δh (m) — survey-monitor contract column** |
| `median` | float | median Δh (m) |
| `std` | float | std of Δh (m) |
| `minimum` | float | min Δh (m) |
| `maximum` | float | **max Δh (m) — survey-monitor contract column** |
| `p10` | float | 10th percentile of Δh (m) |
| `p90` | float | 90th percentile of Δh (m) |
| `valid_pixels` | float | valid pixels in zone |
| `total_pixels` | float | total pixels in zone (same; kept for schema parity) |
| `cloud_cover` | float | percent 0–100, suite convention (DEMs: usually 0) |
| `cut_m3` | float | ground removed (m³, ≥ 0) |
| `fill_m3` | float | ground added (m³, ≥ 0) |
| `net_m3` | float | `fill_m3 − cut_m3` (signed) |
| `max_cut_depth` | float | most negative Δh (m, ≤ 0) |
| `max_fill_height` | float | most positive Δh (m, ≥ 0) |
| `area_m2` | float | valid zone area (m²) |
| `volume_sigma_m3` | float | σ_V lower bound (m³); empty when RMSEs not supplied |
| `confidence` | string | `high` \| `medium` \| `low` (see docs/MATHS.md) |

## survey-monitor mapping

A monitor site config per zone can threshold the contract columns
directly:

- `mean` — watch for settlement/heave trends (e.g. alert if mean Δh < −0.05 m)
- `maximum` — watch for max fill height or (via absolute value) max cut depth
- `net_m3`, `cut_m3`, `fill_m3` — documented for monitor metric configs
  that read them directly (per-site volume budgets, e.g. "alert when a
  month's cut exceeds the permitted 50,000 m³")
