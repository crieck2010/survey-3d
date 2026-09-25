# The maths of survey-3d

Accessible derivations for every number the engine reports. Units are
**metres** for heights and **cubic metres** for volumes unless stated.

## 1. Differencing

For two coregistered elevation models on the same grid:

```
Δh[i,j] = dem2[i,j] − dem1[i,j]
```

A pixel is **valid** only where *both* DEMs are valid (NaN propagates).
The **noise floor** `f` (metres) is the minimum detectable change:

```
changed[i,j]  ⟺  |Δh[i,j]| ≥ f
```

Rationale: every DEM carries vertical noise (sensor, matching,
interpolation). Summing sub-noise fluctuations over thousands of pixels
manufactures cubic metres out of nothing. The floor is a hard gate —
below it, Δh is treated as exactly 0 in volumetrics. The *raw* (ungated)
difference is always kept alongside so nothing is hidden.

## 2. Volumetrics

Let `A` be the pixel area in m² and `Z` the set of valid, changed pixels
in a zone:

```
cut  =  Σ max(−Δh, 0) · A        (ground removed, ≥ 0)
fill =  Σ max(Δh, 0)  · A        (ground added,  ≥ 0)
net  = fill − cut                (signed; negative = export)
```

This is the prism method: each pixel is a vertical column of base `A`
and height `|Δh|`. It is exact for the raster as given — any error comes
from the DEMs, not the arithmetic.

## 3. Uncertainty propagation

Suppose each DEM has a known vertical RMSE, σ₁ and σ₂ (metres), and
pixel errors are **independent** with zero mean. The difference pixel's
error variance is the sum of variances:

```
σ_Δh = √(σ₁² + σ₂²)
```

Volume is a linear combination of N pixel differences, so

```
σ_V = A · σ_Δh · √N
```

**The independence assumption is optimistic.** Real DEM errors are
spatially correlated (a tilt, a datum shift, a matching artefact moves
whole neighbourhoods together), and correlated errors add linearly, not
in quadrature. The true uncertainty lies between σ_V (independent) and
A·σ_Δh·N (fully correlated) — usually much closer to the latter for
systematic effects. Treat the reported σ_V as a **lower bound**.

The `confidence` flag is the volume signal-to-noise ratio SNR = |net|/σ_V:

| SNR | confidence |
|---|---|
| ≥ 5 | high |
| ≥ 2 | medium |
| < 2 or σ unknown | low |

It answers "is this volume distinguishable from noise?", not "is this
volume correct?".

## 4. Coregistration bias

Over a stable area S (roads, buildings, undisturbed ground):

```
bias = median(Δh over S)
```

If the DEMs are perfectly coregistered and the area truly stable,
bias ≈ 0. A non-zero bias means a systematic offset (datum shift,
misregistration) that contaminates *every* volume. The check uses the
median so a few changed pixels (a parked truck) don't trigger it, and
the median absolute deviation (MAD) as the robust spread.

Rule of thumb for the pass threshold: ~2× the combined vertical RMSE.
Failing the check means *re-coregister the DEMs*, not *subtract the
bias* — a single scalar can't fix a tilt or a horizontal shift.

## 5. Polygon tracing

Change polygons come from 8-connected components of the thresholded
`|Δh|` mask. Each component's boundary is traced by chaining directed
pixel edges (interior on the left), giving the exterior ring; interior
rings become holes. Per-feature cut/fill are the prism sums over the
component's pixels, so polygon volumes reconcile with zonal volumes.
