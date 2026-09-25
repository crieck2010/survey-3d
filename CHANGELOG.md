# Changelog

All notable changes to survey-3d will be documented here. The format is
based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [0.1.0] - 2026-09-25

### Added
- DEM differencing (`dem2 − dem1`) with NaN-honest handling, configurable
  noise floor, and grid/CRS comparability guards (never resamples silently)
- Per-zone cut/fill volumetrics: cut/fill/net m³, mean/median Δh, max cut
  depth, max fill height, incremental CSV time series deduped on
  (zone_id, pass_id, index)
- Uncertainty propagation from per-DEM vertical RMSEs (σ_V lower bound,
  independence assumption documented as optimistic) and high/medium/low
  confidence flags from the volume signal-to-noise ratio
- Coregistration bias diagnostic: median Δh over a user-supplied stable
  area, with pass/fail threshold
- Change polygons: 8-connected components, boundary edge-chaining with
  holes preserved, per-feature cut/fill volumes, GeoJSON output
- Diverging Δh QGIS style (red = cut, blue = fill)
- Seeded synthetic demo (known 18,750 m³ cut / 12,300 m³ fill, recovered
  within ~2%): `survey-3d demo`
- Docs: README, MATHS.md, TIMESERIES_SCHEMA.md, DIFF_SPEC.md, DATUMS.md
- 50 pytest tests, all passing
