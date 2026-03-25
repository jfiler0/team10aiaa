# D2500 Wave Drag — MATLAB Interface

## Overview

D2500 (also called AWAVE) computes the **zero-lift wave drag coefficient CDw** of a complete aircraft configuration at supersonic speeds. It implements the area-rule method of Whitcomb and Jones, extended by Eminton-Lord to non-circular fuselages and non-planar wing-body combinations.

The MATLAB interface consists of two functions:

| Function | Purpose |
|---|---|
| `write_awave_input(cfg, filename)` | Build a D2500 input file from a MATLAB struct |
| `runAwave(inputFile)` | Run the exe and return parsed results |

You can either write the struct from scratch (described in this document), or pass one of the provided `.inp` example files directly to `runAwave` without using `write_awave_input` at all.

---

## Quick Start

```matlab
out = runAwave(fullfile('Examples', 'case1.inp'));
fprintf('CDw = %.5f\n', out.CDW(end));
```

Or build from a struct:

```matlab
cfg = struct();
cfg.title = 'My Aircraft';
cfg.REFA  = 608.0;          % ft^2, same units as all geometry

% ... fill in wing and fuselage (see below) ...

inpFile = write_awave_input(cfg, 'my_case.inp');
out     = runAwave(inpFile);
fprintf('CDw = %.5f\n', out.CDW(end));
```

---

## Output Fields

`out = runAwave(inputFile)` returns a struct with:

| Field | Description |
|---|---|
| `out.CDW` | Wave drag coefficient CDw, one value per Mach/cycle [Nx1] |
| `out.DoverQ` | D/Q (drag per dynamic pressure, ft²) corresponding to each CDw [Nx1] |
| `out.Mach` | Mach number for each CDw value [Nx1] |
| `out.cycle` | Fuselage reshaping cycle number for each CDw value [Nx1] |
| `out.raw` | Full text of wavedrag.out as a string |
| `out.status` | system() return code (0 = success) |
| `out.inputFile` | Absolute path of the input file used |

For a simple analysis-only run (no body reshaping, `ICYC=0`), there will be one CDw value per Mach condition. For fuselage optimisation runs (`ICYC>0`), there is one CDw per cycle — take `out.CDW(end)` for the final result.

---

## Units

D2500 is **unit-agnostic** — it works in whatever units you provide as long as you are consistent throughout. The most common choice is **feet** for length and **ft²** for area (matching NASA conventions). All geometry — `WAFORG`, `XFUS`, `REFA` — must be in the same unit.

---

## cfg Struct Reference

### Required Fields

#### `cfg.title`  *(string, max 80 characters)*
A descriptive label for the case. Appears in the output file.

```matlab
cfg.title = 'F-15 WING-BODY  MACH 1.2';
```

#### `cfg.REFA`  *(scalar)*
Reference area used to non-dimensionalise CDw.

```matlab
cfg.REFA = 608.0;   % ft^2  (F-15 wing reference area)
```

> **How to get it:** Use the trapezoidal wing reference area, the same value you use for CL and CD in your aero model. For a complete aircraft this is normally the gross wing area including the portion inside the fuselage.

---

### Wing Fields

Provide all three (`XAF`, `WAFORG`, `WAFORD`) or omit all three to run a fuselage-only case.

#### `cfg.XAF`  *(1 × NXAF row vector)*
Chordwise stations expressed as **percent chord** (0 to 100).

```matlab
cfg.XAF = [0, 5, 10, 20, 30, 40, 50, 60, 70, 80, 90, 95, 100];
```

Rules of thumb:
- Use at least 10–15 stations for smooth ordinates.
- Cluster points near the leading edge (0–10%) where curvature is highest.
- Always include 0 and 100 exactly.
- More stations = more accurate volume distribution but slower solve.

> **How to get it:** These are just the x/c locations at which you know your airfoil shape. If you only have a NACA 4/5-digit section, 13 stations as above is fine. If you are reading from a CAD or XFOIL file, use those x/c locations directly.

#### `cfg.WAFORG`  *(NWAF × 4 matrix)*
Spanwise stations for the wing. One row per station.

```
Column 1: xLE   — x-coordinate of the leading edge at this station (same unit as REFA)
Column 2: y     — spanwise coordinate (semi-span, measured from centreline)
Column 3: z     — vertical offset of the wing reference plane at this station
Column 4: chord — local chord length
```

```matlab
%              xLE      y       z    chord
cfg.WAFORG = [ 10.0,   0.0,   0.0,  25.0;   % root station
               18.0,   5.0,  -0.2,  20.0;   % mid-span
               28.0,  12.0,  -0.5,  10.0;   % tip station
             ];
```

Rules of thumb:
- Include at least root, one mid-span station, and tip (NWAF ≥ 2, typically 3–10).
- More stations resolve taper, sweep, and dihedral better.
- For a swept wing the xLE value increases with span (swept back → increasing xLE).
- For dihedral, z increases (upward dihedral → increasing z with y).

> **How to get it:** From your wing planform layout. `xLE(y)` is the LE x-location at each span station, which you can read directly off a three-view drawing or CAD model. For a simple trapezoidal wing:
> ```matlab
> xLE_root = 0;
> xLE_tip  = xLE_root + b_half * tan(sweep_LE_rad);
> ```

#### `cfg.WAFORD`  *(NWAF × NXAF matrix)*  — symmetric airfoil
Wing ordinates expressed as **percent chord** (z/c × 100) at each `[station, XAF]` combination.

```matlab
% NACA 0006: z/c = 0.06 * t(x/c)  where t is the NACA thickness function
% Pre-computed at each XAF station for each spanwise station:
cfg.WAFORD = [0.00, 0.85, 1.10, 1.34, 1.44, 1.40, 1.26, 1.03, 0.72, 0.36, 0.09, 0.03, 0.00;
              0.00, 0.82, 1.06, 1.28, 1.37, 1.33, 1.19, 0.97, 0.67, 0.33, 0.08, 0.02, 0.00];
```

If upper and lower surfaces differ (cambered airfoil), use `WAFORD_upper` and `WAFORD_lower` instead (see below).

> **How to get it:**
> For a **NACA 4-digit section** with thickness ratio t:
> ```matlab
> xc = cfg.XAF / 100;   % convert percent to fraction
> t_func = 5*t * (0.2969*sqrt(xc) - 0.1260*xc - 0.3516*xc.^2 + 0.2843*xc.^3 - 0.1015*xc.^4);
> waford_row = t_func * 100;   % back to percent chord, upper surface
> ```
> For **XFOIL output**: read the x,z columns and interpolate to your XAF grid. Remember XFOIL uses z/c (fraction), D2500 uses percent (multiply by 100).
> For **CAD**: extract the airfoil cross-section at each span station and sample at XAF locations.

#### `cfg.WAFORD_upper` and `cfg.WAFORD_lower`  *(NWAF × NXAF)*  — cambered airfoil
Use these instead of `cfg.WAFORD` when upper and lower surfaces differ (i.e. the airfoil has camber).

```matlab
cfg.WAFORD_upper = [...];   % z/c * 100, upper surface (positive z)
cfg.WAFORD_lower = [...];   % z/c * 100, lower surface (negative z toward TE)
```

> **Relationship to thickness and camber:**
> For a cambered section with thickness distribution t(x) and camber line zc(x):
> ```
> WAFORD_upper(x) = (zc(x) + t(x)/2) * 100
> WAFORD_lower(x) = (zc(x) - t(x)/2) * 100
> ```

#### `cfg.TZORD`  *(NWAF × NXAF)*  — optional twist/offset
Additional z-offset applied on top of WAFORD at each station. Used when the wing has geometric twist (the entire section is rotated) or when the wing reference plane (z=0 in WAFORG col 3) does not pass through the airfoil LE.

For most configurations this is zero (omit it).

```matlab
% Apply 3 deg washout (nose-down) at tip, linearly interpolated
twist_tip = -chord_tip * sind(3);   % z-offset at tip LE
cfg.TZORD = linspace(0, twist_tip, NWAF)' * ones(1, NXAF);
```

> **When you need it:** If your WAFORG z-column already places the wing at the correct vertical position, and your airfoil ordinates are in the wing's local coordinate system, TZORD = 0. You only need TZORD when accounting for twist angle changes in the z-distribution of the airfoil relative to a flat reference plane.

---

### Fuselage Fields

Provide all fuselage fields or omit them all for a wing-only case.

The fuselage is described as **one or more segments**, each being a list of axial stations. Segments share their endpoint — the last point of segment N equals the first point of segment N+1. Split into multiple segments when:
- There is a step change in cross-sectional area (engine inlet, wing-body junction)
- You want fuselage reshaping applied to only part of the body
- The body exceeds 30 stations in a single segment (D2500 max per segment)

#### `cfg.XFUS`  *(cell array of row vectors)*
Axial (x) stations for each fuselage segment. Each cell contains a vector of x-locations.

```matlab
cfg.XFUS{1} = [0,  5, 10, 15, 20, 25, 30];   % nose
cfg.XFUS{2} = [30, 50, 70, 90, 110];          % constant section
cfg.XFUS{3} = [110, 120, 130, 140, 150];      % tail taper
```

Rules of thumb:
- Minimum 3 stations per segment, typically 5–20.
- Use closer spacing where the area changes rapidly (nose, tail, wing junction).
- The segments must be contiguous: `XFUS{k}(end)` = `XFUS{k+1}(1)`.

> **How to get it:** Read x-stations from your fuselage loft. In CAD, sample cross-sections at regular axial intervals. At the nose and tail, halve the spacing.

#### `cfg.FUSARD`  *(cell array of row vectors)*
Cross-sectional **area** at each axial station in `XFUS`, in the same units as your geometry squared.

```matlab
cfg.FUSARD{1} = [0, 12.6, 43.0, 90.0, 140.0, 180.0, 201.0];  % ft^2
cfg.FUSARD{2} = [201.0, 201.0, 201.0, 201.0, 201.0];
cfg.FUSARD{3} = [201.0, 160.0, 100.0, 40.0, 0.0];
```

Notes:
- Must start at 0 (pointed nose) and end at 0 (pointed tail) for wave drag to be physically meaningful — a blunt base produces a base drag term not captured here.
- For a circular fuselage of radius r: `area = pi * r^2`.
- For a non-circular cross-section: compute the actual cross-sectional area.

> **How to get it:**
> - **From radius**: `FUSARD = pi * r.^2`
> - **From diameter**: `FUSARD = pi * (d/2).^2`
> - **From CAD**: request cross-section areas from your fuselage solid model at each XFUS station.
> - **From conceptual sizing**: if you know the fuselage volume and have a shape, use the Sears-Haack distribution as a starting point:
>   ```matlab
>   x_norm = (x - x_nose) / L;                          % 0 to 1
>   S_max  = 3*pi*V / (8*L);                             % max cross-section for Sears-Haack
>   FUSARD = S_max * (16/3) * (x_norm.*(1-x_norm)).^(3/2);
>   ```
>   where V is fuselage volume and L is fuselage length.

#### `cfg.ZFUS`  *(cell array of row vectors)*  — optional, non-circular fuselage
Vertical offset of the fuselage centroid at each axial station. Provide this when the fuselage cross-section is non-circular (e.g. blended wing-body, oval section, off-axis engine nacelle).

```matlab
cfg.ZFUS{1} = [0, 0.1, 0.2, 0.3, 0.3, 0.2, 0.1];   % drooped nose
```

For a conventional circular fuselage on the x-axis, omit this field entirely.

---

### Case Fields

#### `cfg.cases`  *(struct array)*
One element per Mach condition to run. All Mach conditions share the same geometry.

```matlab
cfg.cases(1).Mach   = 1.2;    % Mach number
cfg.cases(1).NX     = 50;     % number of axial integration stations
cfg.cases(1).NTHETA = 16;     % number of azimuthal cutting planes
cfg.cases(1).ICYC   = 0;      % reshaping cycles (0 = analysis only)
```

**Multi-Mach sweep** — just add more elements:

```matlab
cfg.cases(1).Mach = 2.4;  cfg.cases(1).NX = 60;  cfg.cases(1).NTHETA = 16;  cfg.cases(1).ICYC = 0;
cfg.cases(2).Mach = 2.0;  cfg.cases(2).NX = 60;  cfg.cases(2).NTHETA = 16;  cfg.cases(2).ICYC = 0;
cfg.cases(3).Mach = 1.6;  cfg.cases(3).NX = 60;  cfg.cases(3).NTHETA = 16;  cfg.cases(3).ICYC = 0;
cfg.cases(4).Mach = 1.2;  cfg.cases(4).NX = 60;  cfg.cases(4).NTHETA = 16;  cfg.cases(4).ICYC = 0;
```

#### Case sub-fields

| Field | Type | Default | Description |
|---|---|---|---|
| `.Mach` | scalar | — | Mach number. Must be > 1.0 for wave drag computation. At M=1.0 use NTHETA=1. |
| `.NX` | integer | — | Axial integration stations. 50 is standard; 60–100 for high accuracy. |
| `.NTHETA` | integer | — | Azimuthal cutting planes. 16 is standard; 8 is acceptable for fast sweeps; use 1 only at M=1.0. |
| `.ICYC` | integer | 0 | Fuselage reshaping cycles. 0 = pure analysis. 2–4 = allow D2500 to suggest an area-ruled fuselage shape. |
| `.NREST` | integer | 0 | Number of fuselage x-locations that must remain unchanged during reshaping. |
| `.XREST` | vector | [] | x-coordinates of the restraint points (length = NREST). |

> **NX and NTHETA guidance:**
> - `NX = 50` is sufficient for most configurations.
> - `NTHETA = 16` resolves asymmetric configurations well. For a symmetric wing-body with no dihedral or yaw, even `NTHETA = 8` gives good results.
> - Doubling NX gives ~4× more computation with diminishing returns past NX = 80.

---

## Complete Example — Supersonic Fighter

```matlab
cfg = struct();
cfg.title = 'SUPERSONIC FIGHTER  WING-BODY';
cfg.REFA  = 608.0;   % ft^2

% Wing: NACA 64A204, 3 spanwise stations
cfg.XAF = [0, 5, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100];

%              xLE      y      z    chord
cfg.WAFORG = [  0.0,   0.0,  0.0,  25.0;   % root
               10.0,  10.0, -0.3,  15.0;   % mid
               20.0,  19.5, -0.6,   4.0 ]; % tip

% NACA 64A204: 4% thickness, symmetric — compute ordinates
xc = cfg.XAF / 100;
tc = 0.04;
t_half = 5*tc * (0.2969*sqrt(xc) - 0.1260*xc - 0.3516*xc.^2 + ...
                  0.2843*xc.^3 - 0.1015*xc.^4);
ord_row = t_half * 100;   % percent chord
cfg.WAFORD = repmat(ord_row, 3, 1);   % same section at all span stations

% Fuselage: 2 segments
cfg.XFUS{1}   = [0,   5,  10,  15,  20,  25,  30];   % nose cone
cfg.FUSARD{1} = [0,  20,  55, 100, 140, 165, 175];   % ft^2

cfg.XFUS{2}   = [30,  40,  50,  60,  70,  80];        % tail
cfg.FUSARD{2} = [175, 175, 160, 130, 80,    0];

% Cases: Mach sweep
cfg.cases(1).Mach = 1.6;  cfg.cases(1).NX = 50;  cfg.cases(1).NTHETA = 16;  cfg.cases(1).ICYC = 0;
cfg.cases(2).Mach = 1.2;  cfg.cases(2).NX = 50;  cfg.cases(2).NTHETA = 16;  cfg.cases(2).ICYC = 0;

inpFile = write_awave_input(cfg, 'fighter_case.inp');
out = runAwave(inpFile);

fprintf('Mach    CDw\n');
for k = 1:numel(out.CDW)
    fprintf('%.2f    %.5f\n', out.Mach(k), out.CDW(k));
end
```

---

## Fuselage Area Ruling (Body Reshaping)

Set `ICYC > 0` to ask D2500 to iteratively reshape the fuselage to minimise wave drag at that Mach. The result is printed in `wavedrag.out` as **BODY AREAS FOR NEXT CYCLE** — this is the area-ruled fuselage shape.

```matlab
cfg.cases(1).Mach  = 1.2;
cfg.cases(1).NX    = 50;
cfg.cases(1).NTHETA = 16;
cfg.cases(1).ICYC  = 3;    % 3 reshaping cycles

% Optionally lock certain fuselage stations (e.g. at cockpit and engine face)
cfg.cases(1).NREST  = 2;
cfg.cases(1).XREST  = [15.0, 50.0];   % x-locations that cannot change
```

`out.CDW` will contain one value per cycle. The final value `out.CDW(end)` is the minimum achievable CDw for that area distribution. Compare `out.CDW(1)` (original) to `out.CDW(end)` (area-ruled) to see the benefit.

---

## Limitations and Notes

| Limitation | Value |
|---|---|
| Max spanwise stations (NWAF) | 20 |
| Max chordwise stations (NXAF) | 30 |
| Max fuselage segments | 4 |
| Max fuselage stations per segment | 30 |
| Max total fuselage stations | 101 |
| Mach range | > 1.0 (subsonic not computed) |
| Lift-dependent wave drag | Not included — this is zero-lift only |

This is a **zero-lift** wave drag tool. For accurate total supersonic drag you must add:
- Zero-lift wave drag (CDw from this tool)
- Lift-dependent wave drag (~CL²/... from a Mach-appropriate drag polar)
- Friction drag (from the Friction tool)
- Induced drag (from the iDrag tool)
