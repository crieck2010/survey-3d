> [!IMPORTANT]
> **Consolidated into [EarthWatch-Suite](https://github.com/crieck2010/earthwatch-suite)**  
> This engine has been consolidated into the unified [EarthWatch-Suite monorepo](https://github.com/crieck2010/earthwatch-suite). Active development, bug fixes, releases, and unified testing now live in earthwatch-suite. This repository is preserved as an archive.

# survey-3d

> **Part of [earthwatch-suite](https://github.com/crieck2010/earthwatch-suite)** —
> the remote-sensing project (satellite imagery, change detection, site
> monitoring). Terrestrial surveying lives in
> [survey-suite](https://github.com/crieck2010/survey-suite); the two stay
> compatible through the
> [cross-suite contracts](https://github.com/crieck2010/earthwatch-suite/blob/main/docs/CONTRACTS.md).

The **DSM/DEM differencing and cut/fill volumetrics engine** for
earthwatch-suite: take two elevation models (stereo satellite pairs,
LiDAR, drone photogrammetry), difference them, and quantify the earthwork
— cut volumes, fill volumes, net change, per-zone volumetric time series,
change polygons, and a coregistration sanity check. Construction and
mining: this is the engine that turns "the ground moved" into cubic
metres.

Engine-first and stdlib+numpy at the core: every analytic function takes
numpy arrays, so the engine embeds in scripts, pipelines, and desktop
apps. GeoTIFF I/O is a thin lazy-rasterio boundary (`pip install
"survey-3d[raster]"`).

## Quickstart

```bash
pip install .
# with GeoTIFF support:
pip install "survey-3d[raster]"

# The whole pipeline on seeded synthetic data — no downloads, no files:
survey-3d demo
```

The demo builds a synthetic 100×100 site (10 m pixels) with a planted
**18,750 m³ cut** and **12,300 m³ fill**, then runs the full pipeline:
coregistration check → differencing → per-zone volumetrics → change
polygons. Expect output like:

```
cut-pit:    cut=18909 m³ fill=0 m³     net=-18909 m³ σ=193 m³ [high]
fill-mound: cut=0 m³     fill=12035 m³ net=+12035 m³ σ=193 m³ [high]
```

## CLI

| Command | What it does |
|---|---|
| `survey-3d diff --dem1 A.tif --dem2 B.tif [--noise-floor 0.08] [--out diff.tif]` | `dem2 − dem1` difference raster (GeoTIFF + `.qml` style) |
| `survey-3d volumes --diff diff.tif --zones zones.geojson [--rmse1 0.03 --rmse2 0.03]` | per-zone cut/fill → incremental `volumes.csv` |
| `survey-3d polygons --diff diff.tif [--threshold 0.10]` | vectorize change areas → GeoJSON |
| `survey-3d coreg --dem1 A.tif --dem2 B.tif --stable stable.geojson` | bias diagnostic over stable ground |
| `survey-3d demo` | full synthetic pipeline (see above) |

Every command also accepts `--synthetic` to run on the seeded demo data
instead of files.

## The maths

**Differencing.** Δh = dem2 − dem1, pixelwise. NaN (nodata in either DEM)
propagates: a pixel is valid only where *both* DEMs are valid. A noise
floor (metres) marks the minimum detectable change — `|Δh|` below it is
no-change. Without one, volumetrics integrate DEM noise into phantom
cubic metres.

**Volumetrics.** For a zone: cut = Σ(−Δh)·A over pixels with Δh < 0,
fill = Σ(Δh)·A over pixels with Δh > 0, where A is the pixel area (m²).
Net = fill − cut (signed: negative net means ground left the site).

**Uncertainty.** Given per-DEM vertical RMSEs σ₁, σ₂, the per-pixel
difference error is σ_Δh = √(σ₁² + σ₂²). *Assuming independent pixel
errors*, σ_V = A·σ_Δh·√N. That independence assumption is **optimistic** —
real DEM errors are spatially correlated, so the true uncertainty is
larger; the reported σ_V is a lower bound. The `confidence` flag
(high/medium/low) comes from the volume signal-to-noise ratio
|net|/σ_V (≥5 / ≥2 / else). Without RMSEs there is no σ, so confidence is
always "low" — the honest answer when uncertainty is unquantified.

**Coregistration.** The median Δh over a user-supplied stable area
(roads, undisturbed ground). If the "stable" ground moved beyond the
threshold, the DEMs aren't comparable and every volume downstream is
suspect. Median, not mean, so a parked truck doesn't fail the check.

Full derivations: [`docs/MATHS.md`](docs/MATHS.md).

## Suite integration

- **survey-monitor**: the `mean`/`maximum` Δh columns are the monitor's
  contract — a site config per zone can threshold mean settlement or max
  fill height. `net_m3`/`cut_m3`/`fill_m3` are documented for monitor
  metric configs that read them directly.
- **survey-change**: difference rasters are first-class change inputs
  (transition matrices over change classes).
- **survey-qgis**: the Δh GeoTIFF + `.qml` (red = cut, blue = fill)
  opens directly in QGIS; the engine's algorithms are candidates for
  future Processing-algorithm wiring.
- **survey-geodesy** (survey-suite): vertical-datum conventions live
  there; this engine assumes both DEMs already share a CRS and vertical
  datum — see [`docs/DATUMS.md`](docs/DATUMS.md).

## Limitations (read before quoting volumes)

- **Coregistration is everything.** Unaligned DEMs produce beautiful,
  precise, wrong volumes. Run `coreg` first, every time.
- **Resolution vs. precision.** A 30 m DEM cannot resolve a 2 m
  stockpile; the noise floor must reflect the DEM's actual vertical
  accuracy, not your ambition.
- **Vegetation and structures corrupt bare-earth differencing.** DSMs
  include trees and buildings — a cleared forest reads as a 15 m "cut".
  Difference DSM-to-DSM for surface change, DTM-to-DTM for bare earth,
  and never mix them silently.
- **Uncertainty is a lower bound** (see the maths above).
- This is a screening/quantity-estimation tool, **not a certified
  quantity survey** — volumes for payment need a licensed surveyor's
  workflow.

## File layout

```
src/elev3d/
  diff.py        DEM differencing + noise floor + grid checks
  volumes.py     cut/fill volumetrics + uncertainty + confidence
  coreg.py       coregistration bias diagnostic over stable areas
  polygons.py    connected components + boundary tracing → GeoJSON
  timeseries.py  incremental per-zone volume CSV (dedupe on zone+pair)
  zones.py       GeoJSON zone loading (interchangeable with siblings)
  zonal.py       pure-numpy zone masks
  synthetic.py   seeded demo DEMs (known 18,750 m³ cut / 12,300 m³ fill)
  acquire.py     lazy-rasterio GeoTIFF I/O + CRS-match guard
  qml.py         diverging Δh QGIS style (red=cut, blue=fill)
  cli.py         diff | volumes | polygons | coreg | demo
docs/
  MATHS.md               derivations: differencing, volumetrics, uncertainty
  TIMESERIES_SCHEMA.md   volume CSV column reference
  DIFF_SPEC.md           difference-raster and polygon specs
  DATUMS.md              CRS / vertical-datum conventions and assumptions
```

## License

MIT — see [LICENSE](LICENSE).
