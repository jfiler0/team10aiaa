%% RCS_COMPARE_MULTIPLE_STL.m
% Compare multiple aircraft STL meshes with a monostatic PO-style RCS metric,
% then calibrate results to comparator aircraft with known/assumed frontal RCS.
%
% What this does:
%   1) Loads multiple STL files
%   2) Computes PO-based RCS vs azimuth  (formula: sigma = 4*pi/lambda^2 * |S|^2)
%   3) Applies per-model calibration from a known seed RCS
%   4) Plots calibrated sweeps and comparator summary
%
% Bug fixes vs. previous version:
%   - Added missing 1/lambda^2 factor in RCS formula (was giving m^4, not m^2)
%   - Switched from single global offset to per-model calibration
%     (global offset collapses when models span orders of magnitude in raw RCS)
%   - Prints bounding box per model so you can verify unitScale is correct
%   - Fixed axis label strings (single backslash, no interpreter warnings)
%
% Notes:
%   - PEC, monostatic, no edge diffraction, no cavity physics, no RAM model.
%   - Use for relative trade studies, not absolute truth.

clear; clc; close all;

%% ---------------- USER INPUTS ----------------
c0     = 299792458;
f      = 10e9;            % radar frequency [Hz]  (X-band default)
lambda = c0 / f;
k      = 2*pi / lambda;

thetaDeg = 90;            % elevation cut (90 = level / horizontal)
phiSweep = 0:2:358;       % azimuth sweep [deg]

% Calibration metric used to anchor each model to its known seed RCS:
%   'frontal' = phi = 0 deg
%   'median'  = median over full sweep
%   'mean'    = mean over full sweep
calMetric = 'frontal';

% PO summation mode (applied to all models unless overridden by poModeOverride):
%   'coherent'       phase-accurate sum; realistic lobing but specular spikes.
%   'incoherent'     sum of (A_n cosθ_n)^2; rough-surface assumption.
%                    Used for fighter comparators.
%   'projected_area' σ = Σ A_n cosθ_n; blind to surface shaping.
%   'specular_area'  σ = Σ A_n cos^2(θ_n); captures LE/TE shaping.
%                    Used for Hellstinger via poModeOverride.
poMode = 'incoherent';

% ---- MODEL LIST ----
% knownRCS_m2 : frontal (nose-on) X-band seed RCS to anchor calibration [m^2]
% unitScale   : multiply STL vertex coords by this to get meters
% rotAxis/rotDeg : rotate mesh so fuselage points along +Y before sweeping
%
% Convention used here:
%   +Y = nose direction (frontal = phi=90, tail = phi=270)
%   +X = starboard wing (beam = phi=0 or phi=180)
%   +Z = up
%   theta=90 sweep is a horizontal circle around the aircraft
%
% How fuselage axes were identified (match bounding box to real dims):
%   F-16:   fuselage along STL-Y  -> already correct, no rotation needed
%   F/A-18: fuselage along STL-Z  -> rotate -90 deg about X to bring Z->Y
%   Rafale: fuselage along STL-Z  -> rotate -90 deg about X to bring Z->Y

models = struct([]);

models(1).name            = 'F-16';
models(1).file            = 'F16STLV2.stl';
models(1).unitScale       = 0.077;
models(1).rotAxis         = [1 0 0];
models(1).rotDeg          = 0;
models(1).knownRCS_m2     = 4.0;
models(1).color           = [0.85 0.33 0.10];
models(1).poModeOverride  = '';
models(1).isComparator    = true;

models(2).name            = 'F/A-18E/F Super Hornet';
models(2).file            = 'F_A-18E_v3.stl';
models(2).unitScale       = 6.0;
models(2).rotAxis         = [1 0 0];
models(2).rotDeg          = -90;
models(2).knownRCS_m2     = 1.0;
models(2).color           = [0.00 0.45 0.74];
models(2).poModeOverride  = '';
models(2).isComparator    = true;

models(3).name            = 'Dassault Rafale';
models(3).file            = 'Rafale.stl';
models(3).unitScale       = 0.0136;
models(3).rotAxis         = [1 0 0];
models(3).rotDeg          = -90;
models(3).knownRCS_m2     = 2.0;
models(3).color           = [0.47 0.67 0.19];
models(3).poModeOverride  = '';
models(3).isComparator    = true;

% ---- Hellstinger ----
% STL: TestAssm_PDR_V2.STL  (PDR revision)
% Units: mm -> unitScale = 0.001.  Fuselage along STL-X, +90 deg
% about Z brings it to +Y.
%
% Post-rotation bounding box (verified from mesh):
%   Lx =  3.63 m  (body width)
%   Ly = 15.44 m  (body length / fuselage)
%   Lz = 18.20 m  (solar array / vertical extent — grew from 10.83 m in prior rev)
%
% Mesh quality: 3,702 triangles, 0 open edges, 0 non-manifold (watertight).
% Surface area: ~276.9 m^2 (consistent with prior revision).
%
% Uses 'projected_area' mode (geometric optics diffuse limit):
%   sigma(phi) = A_proj(phi)  [m^2]
% Mesh-independent and correct for large bodies with non-uniform facet sizes.
%
% Seed: frontal specular_area = 1.646 m^2 (computed from PDR_V2 mesh at phi=90).
% Beam naturally calibrates to ~95.9 m^2. Beam/frontal ~58x (17.7 dB).
% This is physically between projected_area (10.9 dB, blind to shaping) and
% incoherent PO (24.9 dB, facet-size biased). The cos^2 weighting suppresses
% swept LE/TE surfaces (cos^2 << 1) relative to flat broadside panels (cos^2 ~ 1),
% correctly giving shaping credit that projected_area mode misses entirely.
models(4).name            = 'Hellstinger';
models(4).file            = 'TestAssm_PDR_V2.STL';
models(4).unitScale       = 0.001;
models(4).rotAxis         = [0 0 1];
models(4).rotDeg          = 90;
models(4).knownRCS_m2     = 1.646;   % frontal specular_area, PDR_V2 mesh [m^2]
models(4).color           = [0.75 0.2 0.9];
models(4).poModeOverride  = 'specular_area';
models(4).isComparator    = true;

% ---- RAM: uniform dB reduction per model ----
% Applied as a flat scalar after geometry computation, preserving polar shape.
% This is appropriate for a trade study where coating angle-response is unknown.
%
% ram_dB = broadband attenuation target in dB (positive = reduction).
%   0 dB  -> no RAM, full PEC reflection (default)
%   3 dB  -> light surface treatment (~50% power reduction)
%   6 dB  -> moderate RAM
%  10 dB  -> good RAM (broadband absorber, Salisbury screen / Jaumann)
%  20 dB  -> stealth-grade RAM (multilayer, optimised for X-band)
%

% Note: the Leontovich angle-dependent model (Z_s) was removed because it
% changes the SHAPE of the polar pattern by differentially absorbing normal-
% vs grazing-incidence facets, producing a physically misleading butterfly
% shape. A uniform dB reduction correctly models a broadband coating spec.

models(1).ram_dB = 0;    % F-16: no RAM
models(2).ram_dB = 20;    % F/A-18E: no RAM
models(3).ram_dB = 20;    % Rafale: no RAM
models(4).ram_dB = 20;    % Hellstinger: no RAM

nModels = numel(models);

%% ---------------- MAIN ANALYSIS ----------------
for m = 1:nModels
    fprintf('\nLoading %s from %s\n', models(m).name, models(m).file);

    [F, V] = stlReadSimple(models(m).file);
    V = V * models(m).unitScale;

    % Apply rotation to align fuselage along +Y
    if models(m).rotDeg ~= 0
        ax  = models(m).rotAxis / norm(models(m).rotAxis);
        ang = deg2rad(models(m).rotDeg);
        c = cos(ang); s = sin(ang); t = 1 - c;
        Rx = ax(1); Ry = ax(2); Rz = ax(3);
        R = [ t*Rx*Rx+c,    t*Rx*Ry-s*Rz, t*Rx*Rz+s*Ry;
              t*Rx*Ry+s*Rz, t*Ry*Ry+c,    t*Ry*Rz-s*Rx;
              t*Rx*Rz-s*Ry, t*Ry*Rz+s*Rx, t*Rz*Rz+c    ];
        V = (R * V').';
    end

    % --- Bounding box sanity check ---
    % After rotation: Lx = wingspan, Ly = fuselage length, Lz = height
    bmin = min(V);  bmax = max(V);
    dims = bmax - bmin;
    fprintf('  Bounding box (post-rotation): Lx=%.2f m (span), Ly=%.2f m (length), Lz=%.2f m (height)\n', ...
        dims(1), dims(2), dims(3));
    fprintf('  Convention: nose-on = phi=90 deg, beam = phi=0/180 deg, tail = phi=270 deg\n');

    geom = preprocessMesh(F, V);

    % Per-model PO mode override
    if isfield(models(m), 'poModeOverride') && ~isempty(models(m).poModeOverride)
        modelPoMode = models(m).poModeOverride;
    else
        modelPoMode = poMode;
    end

    % RAM: uniform dB reduction applied as flat scalar after geometry (preserves shape)
    ramLin = 10^(-models(m).ram_dB / 10);
    if models(m).ram_dB == 0
        ramStr = 'none';
    else
        ramStr = sprintf('%.1f dB reduction (x%.4f linear)', models(m).ram_dB, ramLin);
    end
    fprintf('  PO mode: %s  |  RAM: %s\n', modelPoMode, ramStr);

    rawSigma = computeRawRCSAzimuth(geom, k, lambda, thetaDeg, phiSweep, modelPoMode);
    rawSigma = max(rawSigma * ramLin, 1e-30);   % uniform RAM scaling
    rawDb    = 10*log10(rawSigma);

    models(m).geom        = geom;
    models(m).rawSigma_m2 = rawSigma;
    models(m).rawDbsm     = rawDb;

    % Reference metric used for calibration
    % Convention: fuselage along Y -> nose-on at phi=90, tail at phi=270, beam at phi=0/180
    models(m).rawFrontal_m2 = interp1(phiSweep, rawSigma,  90, 'linear', 'extrap');
    models(m).rawBeam_m2    = 0.5 * ( ...
        interp1(phiSweep, rawSigma,   0, 'linear', 'extrap') + ...
        interp1(phiSweep, rawSigma, 180, 'linear', 'extrap') );
    models(m).rawTail_m2    = interp1(phiSweep, rawSigma, 270, 'linear', 'extrap');
    models(m).rawMedian_m2  = median(rawSigma);
    models(m).rawMean_m2    = mean(rawSigma);

    switch lower(calMetric)
        case 'frontal'; models(m).rawRef_m2 = models(m).rawFrontal_m2;
        case 'median';  models(m).rawRef_m2 = models(m).rawMedian_m2;
        case 'mean';    models(m).rawRef_m2 = models(m).rawMean_m2;
        otherwise;      error('calMetric must be frontal, median, or mean.');
    end
end

%% ---------------- PER-MODEL CALIBRATION ----------------
% Each model gets its own multiplicative scale factor so that its chosen
% reference aspect matches the known seed RCS.  This avoids the collapse
% that happens with a single global offset when raw values span decades.
%
%   calSigma = rawSigma * (knownRef_m2 / rawRef_m2)
%
% The resulting curves are self-consistent within each model; relative
% differences at non-frontal aspects reflect geometry, not absolute truth.

fprintf('\nCalibration metric: %s\n', calMetric);
fprintf('%-30s  %10s  %10s  %10s\n', 'Model', 'Raw ref', 'Known ref', 'Scale');

for m = 1:nModels
    rawRef  = models(m).rawRef_m2;
    known   = models(m).knownRCS_m2;
    scaleLin = known / max(rawRef, 1e-40);

    models(m).scaleLin      = scaleLin;
    models(m).calSigma_m2   = models(m).rawSigma_m2 * scaleLin;
    models(m).calDbsm       = 10*log10(max(models(m).calSigma_m2, 1e-30));

    models(m).calFrontal_m2 = interp1(phiSweep, models(m).calSigma_m2,  90, 'linear', 'extrap');
    models(m).calBeam_m2    = 0.5 * ( ...
        interp1(phiSweep, models(m).calSigma_m2,   0, 'linear', 'extrap') + ...
        interp1(phiSweep, models(m).calSigma_m2, 180, 'linear', 'extrap') );
    models(m).calTail_m2    = interp1(phiSweep, models(m).calSigma_m2, 270, 'linear', 'extrap');
    models(m).calMedian_m2  = median(models(m).calSigma_m2);
    models(m).calMean_m2    = mean(models(m).calSigma_m2);

    fprintf('%-30s  %10.4g  %10.4g  %10.4g\n', ...
        models(m).name, rawRef, known, scaleLin);
end

%% ---------------- PRINT SUMMARY ----------------
fprintf('\n---- Calibrated Summary ----\n');
for m = 1:nModels
    fprintf('%s\n', models(m).name);
    fprintf('  Seed (known) ref RCS : %8.3f m^2  (%+6.2f dBsm)\n', ...
        models(m).knownRCS_m2, 10*log10(models(m).knownRCS_m2));
    fprintf('  Frontal calibrated   : %8.3f m^2  (%+6.2f dBsm)\n', ...
        models(m).calFrontal_m2, 10*log10(max(models(m).calFrontal_m2,1e-30)));
    fprintf('  Beam avg calibrated  : %8.3f m^2  (%+6.2f dBsm)\n', ...
        models(m).calBeam_m2,    10*log10(max(models(m).calBeam_m2,1e-30)));
    fprintf('  Tail calibrated      : %8.3f m^2  (%+6.2f dBsm)\n', ...
        models(m).calTail_m2,    10*log10(max(models(m).calTail_m2,1e-30)));
    fprintf('  Median calibrated    : %8.3f m^2  (%+6.2f dBsm)\n', ...
        models(m).calMedian_m2,  10*log10(max(models(m).calMedian_m2,1e-30)));
    fprintf('  Mean calibrated      : %8.3f m^2  (%+6.2f dBsm)\n\n', ...
        models(m).calMean_m2,    10*log10(max(models(m).calMean_m2,1e-30)));
end

%% ---------------- COMPARATOR CORRECTION FRAMEWORK ----------------
% Computes per-aspect correction factors from the comparator fleet, then
% applies a geometry-weighted blend to estimate corrected RCS for a new
% model when it is added later.
%
% Correction factor at each aspect:
%   CF_m = knownRCS_m / rawPO_m   (= models(m).scaleLin, already computed)
%
% Outlier detection: if a model's log10(scaleLin) deviates more than
% outlierThresh dB from the fleet median, it is flagged and down-weighted.
%
% Geometric weights (when a new model is loaded):
%   similarity to comparator m = exp(-||geomVec_new - geomVec_m||^2 / sigma^2)
%   geomVec = [log10(wingspan), log10(length), log10(surfaceArea)]
%
% Without a new model loaded, this section just reports the fleet
% correction statistics so you can see how consistent the comparators are.

outlierThresh_dB = 10;   % flag comparators whose scale deviates > this from median

scales_dB = 10*log10([models.scaleLin]);
median_dB = median(scales_dB);

fprintf('---- Comparator Correction Statistics ----\n');
fprintf('Fleet median log-scale: %+.2f dB\n', median_dB);
fprintf('%-30s  %10s  %10s  %8s\n', 'Model', 'Scale (dB)', 'Dev (dB)', 'Status');

for m = 1:nModels
    dev = scales_dB(m) - median_dB;
    if abs(dev) > outlierThresh_dB
        status = 'OUTLIER';
        models(m).isOutlier = true;
    else
        status = 'ok';
        models(m).isOutlier = false;
    end
    fprintf('%-30s  %+10.2f  %+10.2f  %8s\n', models(m).name, scales_dB(m), dev, status);

    % Store geometric feature vector for similarity weighting
    bb = max(models(m).geom.C) - min(models(m).geom.C);
    span = max(bb(1), 1e-3);
    len  = max(bb(2), 1e-3);
    sa   = sum(models(m).geom.A) * 2;   % two-sided surface area estimate
    models(m).geomVec = [log10(span), log10(len), log10(sa)];
end

goodIdx = find(~[models.isOutlier]);
fprintf('\nUsable comparators for correction: %d / %d\n', numel(goodIdx), nModels);
if numel(goodIdx) < nModels
    fprintf('  Outlier models contribute zero weight to new-model correction.\n');
end

% Weighted correction scale (dB) from good comparators - equal weight for now
% When a new model is added, replace equal weights with geometry similarity weights
if ~isempty(goodIdx)
    goodScales_dB = scales_dB(goodIdx);
    fleetCorrection_dB  = mean(goodScales_dB);
    fleetCorrection_std = std(goodScales_dB);
    fprintf('  Fleet correction (good comparators): %+.2f +/- %.2f dB\n\n', ...
        fleetCorrection_dB, fleetCorrection_std);
else
    fleetCorrection_dB  = median_dB;
    fleetCorrection_std = 0;
    fprintf('  No good comparators - falling back to fleet median.\n\n');
end

% Store for use by new model analysis
correction.fleetScale_dB  = fleetCorrection_dB;
correction.fleetScale_std = fleetCorrection_std;
correction.goodIdx        = goodIdx;
correction.models         = models;
correction.lambda         = lambda;
correction.k              = k;
correction.phiSweep       = phiSweep;
correction.thetaDeg       = thetaDeg;
correction.poMode         = poMode;

fprintf('Correction struct saved. When new model STL is ready, call:\n');
fprintf('  analyzeNewModel(correction, ''newmodel.stl'', unitScale, rotAxis, rotDeg, name)\n\n');

%% ---------------- PLOTS ----------------
% compIdx: models shown in fleet comparison plots (isComparator = true)
compIdx = find(arrayfun(@(x) x.isComparator, models));
compModelsPlot = models(compIdx);
nComp = numel(compIdx);

figure('Name','Calibrated RCS vs Azimuth');
hold on;
for i = 1:nComp
    m = compIdx(i);
    plot(phiSweep, models(m).calDbsm, 'LineWidth', 1.6, 'Color', models(m).color, ...
        'DisplayName', models(m).name);
end
grid on;
xlabel('Azimuth phi (deg)  [phi=90: nose-on | phi=0,180: beam | phi=270: tail]');
title(sprintf('Calibrated Monostatic RCS vs Azimuth (%s PO), theta = %g deg, f = %.1f GHz', ...
    poMode, thetaDeg, f/1e9));
legend('Location', 'best');

% --- Flower-style polar RCS plot (comparators only) ---
allDbsm = cell2mat(arrayfun(@(x) x.calDbsm(:)', compModelsPlot, 'UniformOutput', false));
globalMin_dB = min(allDbsm(:));
globalMax_dB = max(allDbsm(:));
dRange = globalMax_dB - globalMin_dB;

figure('Name','Polar RCS - Flower Plot','Position',[100 100 700 700], 'color', 'w');
pax = polaraxes;
hold(pax, 'on');

for i = 1:nComp
    m = compIdx(i);
    rho     = [models(m).calDbsm - globalMin_dB, models(m).calDbsm(1) - globalMin_dB];
    phiPlot = deg2rad([phiSweep - 90, phiSweep(1) - 90]);
    polarplot(pax, phiPlot, rho, 'LineWidth', 2.0, 'Color', models(m).color, ...
        'DisplayName', models(m).name);
end

pax.ThetaZeroLocation = 'top';
pax.ThetaDir          = 'clockwise';
pax.GridColor         = [0.5 0.5 0.5];
pax.GridAlpha         = 0.4;

nTicks = 5;
rTicks = linspace(0, dRange, nTicks);
pax.RAxis.Limits = [0, dRange * 1.05];
pax.RTick        = rTicks;
pax.RTickLabel   = arrayfun(@(v) sprintf('%+.0f dBsm', v + globalMin_dB), ...
    rTicks, 'UniformOutput', false);

% After -90 shift: polar 0=top=Nose, 90=right=Beam, 180=bottom=Tail, 270=left=Beam
pax.ThetaTick      = [0 90 180 270];
pax.ThetaTickLabel = {'Nose', 'Beam', 'Tail', 'Beam'};

title(sprintf('Calibrated RCS Polar, theta = %g deg, f = %.1f GHz', ...
   thetaDeg, f/1e9), 'FontSize', 11);
theme(gcf, 'light') 
legend('Location', 'southoutside', 'NumColumns', nComp);

% Comparator bar chart (F-16 excluded)
frontals = arrayfun(@(x) x.calFrontal_m2, compModelsPlot);
beams    = arrayfun(@(x) x.calBeam_m2,    compModelsPlot);
tails    = arrayfun(@(x) x.calTail_m2,    compModelsPlot);
medians  = arrayfun(@(x) x.calMedian_m2,  compModelsPlot);
safeDb   = @(v) 10*log10(max(v, 1e-30));

barData = [safeDb(frontals(:)), safeDb(beams(:)), safeDb(tails(:)), safeDb(medians(:))];

figure('Name','Comparator Metrics');
X = categorical({compModelsPlot.name});
X = reordercats(X, {compModelsPlot.name});
hb = bar(X, barData, 'grouped');
ylabel('RCS (dBsm)');
legend({'Frontal','Beam avg','Tail','Median'}, 'Location', 'best');
grid on;
theme(gcf, 'light') 
title('Comparator RCS Metrics (dBsm)');

% Y-axis: pad 2 dB below min and above max so bars near 0 are visible
ylo = min(barData(:)) - 2;
yhi = max(barData(:)) + 3;
ylim([ylo yhi]);

% Data labels on each bar
for bi = 1:numel(hb)
    xpos = hb(bi).XEndPoints;
    ypos = hb(bi).YEndPoints;
    vals = hb(bi).YData;
    for xi = 1:numel(xpos)
        text(xpos(xi), ypos(xi) + 0.3, sprintf('%.1f', vals(xi)), ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
            'FontSize', 7, 'Color', 'w');
    end
end

% Normalized shape comparison
figure('Name','Normalized Shape Comparison');
hold on;
for i = 1:nComp
    m = compIdx(i);
    normDb = models(m).calDbsm - max(models(m).calDbsm);
    plot(phiSweep, normDb, 'LineWidth', 1.6, 'Color', models(m).color, ...
        'DisplayName', models(m).name);
end
grid on;
xlabel('Azimuth phi (deg)  [phi=90: nose-on | phi=0,180: beam | phi=270: tail]');
ylabel('sigma - sigma_{max} (dB)', 'Interpreter', 'none');
title('Normalized Aspect Signature Comparison');
theme(gcf, 'light') 
legend('Location', 'best');

%% ================================================================
%%  HELLSTINGER — STANDALONE PLOTS
%% ================================================================
% Separate Cartesian and polar plots for Hellstinger only,
% with comparators shown as dashed grey reference lines.

hIdx = find(strcmp({models.name}, 'Hellstinger'));

if ~isempty(hIdx)
    hm = models(hIdx);
    ps = phiSweep;
    phiPlotH = deg2rad([ps - 90, ps(1) - 90]);

    % --- Cartesian: Hellstinger vs comparators ---
    figure('Name','Hellstinger RCS vs Azimuth');
    hold on;
    for m = 1:nModels
        if m == hIdx || ~models(m).isComparator; continue; end
        plot(ps, models(m).calDbsm, '--', 'LineWidth', 1.0, ...
            'Color', [0.55 0.55 0.55], 'DisplayName', models(m).name);
    end
    plot(ps, hm.calDbsm, 'LineWidth', 2.2, 'Color', hm.color, ...
        'DisplayName', hm.name);
    grid on;
    xlabel('Azimuth phi (deg)  [phi=90: nose-on | phi=0,180: beam | phi=270: tail]');
    ylabel('sigma (dBsm)');
    theme(gcf, 'light') 
    title(sprintf('Hellstinger RCS vs Azimuth (specular_area), f = %.1f GHz', f/1e9));
    legend('Location', 'best');

    % --- Polar: Hellstinger vs comparators ---
    allDb2 = hm.calDbsm;
    for m = 1:nModels
        if m ~= hIdx && models(m).isComparator
            allDb2 = [allDb2, models(m).calDbsm]; %#ok<AGROW>
        end
    end
    gMin2 = min(allDb2); gMax2 = max(allDb2); dR2 = gMax2 - gMin2;

    figure('Name','Hellstinger Polar', 'Position', [150 150 700 700]);
    theme(gcf, 'light') 
    pax3 = polaraxes;
    hold(pax3, 'on');

    for m = 1:nModels
        if m == hIdx || ~models(m).isComparator; continue; end
        rho3 = [models(m).calDbsm - gMin2, models(m).calDbsm(1) - gMin2];
        polarplot(pax3, phiPlotH, rho3, '--', 'LineWidth', 1.0, ...
            'Color', [0.55 0.55 0.55], 'DisplayName', models(m).name);
    end
    rhoH = [hm.calDbsm - gMin2, hm.calDbsm(1) - gMin2];
    polarplot(pax3, phiPlotH, rhoH, 'LineWidth', 2.5, 'Color', hm.color, ...
        'DisplayName', hm.name);

    pax3.ThetaZeroLocation = 'top';
    pax3.ThetaDir          = 'clockwise';
    pax3.GridColor         = [0.5 0.5 0.5];
    pax3.GridAlpha         = 0.4;

    nT3 = 5; rT3 = linspace(0, dR2, nT3);
    pax3.RAxis.Limits = [0, dR2 * 1.05];
    pax3.RTick        = rT3;
    pax3.RTickLabel   = arrayfun(@(v) sprintf('%+.0f dBsm', v + gMin2), ...
        rT3, 'UniformOutput', false);
    pax3.ThetaTick      = [0 90 180 270];
    pax3.ThetaTickLabel = {'Nose', 'Beam', 'Tail', 'Beam'};

    title(sprintf('Hellstinger Polar RCS (specular_area), f = %.1f GHz', f/1e9), ...
        'FontSize', 11);
    legend('Location', 'southoutside', 'NumColumns', nModels);

    % --- Summary printout ---
    sdb = @(v) 10*log10(max(v, 1e-30));
    fprintf('\n======= Hellstinger Standalone Summary =======\n');
    fprintf('  Method        : Specular-weighted area (sigma = sum A_n * cos^2(theta_n))\n');
    fprintf('  Frontal       : %8.3f m^2  (%+6.2f dBsm)\n', hm.calFrontal_m2, sdb(hm.calFrontal_m2));
    fprintf('  Beam avg      : %8.3f m^2  (%+6.2f dBsm)\n', hm.calBeam_m2,    sdb(hm.calBeam_m2));
    fprintf('  Tail          : %8.3f m^2  (%+6.2f dBsm)\n', hm.calTail_m2,    sdb(hm.calTail_m2));
    fprintf('  Median        : %8.3f m^2  (%+6.2f dBsm)\n', hm.calMedian_m2,  sdb(hm.calMedian_m2));
    fprintf('  Beam/frontal  : %.1fx  (%.1f dB)\n', ...
        hm.calBeam_m2/hm.calFrontal_m2, sdb(hm.calBeam_m2)-sdb(hm.calFrontal_m2));
    fprintf('  Note: specular_area mode accounts for LE/TE sweep angle alignment.\n');
    fprintf('        Swept surfaces suppressed by cos^2(theta). Uncertainty +/-10 dB.\n');
end

%% ================================================================
%%  HELLSTINGER REVISION COMPARISON
%%  TestAssm_Clean (v1) vs TestAssm_PDR_V2 (v2)
%% ================================================================
% Both run with identical settings: specular_area mode, same rotation,
% same unit scale. Differences in the output are purely geometric.
%
% Pre-computed key values (specular_area mode):
%   v1 Clean:  frontal 1.575 m^2, beam avg 88.2 m^2, beam/frontal 55.5x (17.4 dB)
%   v2 PDR_V2: frontal 1.646 m^2, beam avg 96.5 m^2, beam/frontal 58.3x (17.7 dB)
%
% Beam increase v1->v2: +0.4 dB
%   Cause: body widened 2.94->3.63 m, Lz grew 10.83->18.20 m
%   Both increase broadside projected area.

fprintf('\n======= Hellstinger Revision Comparison =======\n');

revs = struct([]);

revs(1).name      = 'Clean (v1)';
revs(1).file      = 'TestAssm_Clean.STL';
revs(1).unitScale = 0.001;
revs(1).rotAxis   = [0 0 1];
revs(1).rotDeg    = 90;
revs(1).color     = [0.5 0.0 0.8];    % dark purple
revs(1).knownRCS  = 1.5748;           % specular_area frontal [m^2]

revs(2).name      = 'PDR V2';
revs(2).file      = 'TestAssm_PDR_V2.STL';
revs(2).unitScale = 0.001;
revs(2).rotAxis   = [0 0 1];
revs(2).rotDeg    = 90;
revs(2).color     = [0.75 0.2 0.9];   % bright magenta (same as main)
revs(2).knownRCS  = 1.646;            % specular_area frontal [m^2]

nRevs = numel(revs);

for r = 1:nRevs
    fprintf('  Loading %s ...\n', revs(r).name);
    [Frev, Vrev] = stlReadSimple(revs(r).file);
    Vrev = Vrev * revs(r).unitScale;

    ax  = revs(r).rotAxis / norm(revs(r).rotAxis);
    ang = deg2rad(revs(r).rotDeg);
    cs = cos(ang); sn = sin(ang); t = 1-cs;
    Rx=ax(1); Ry=ax(2); Rz=ax(3);
    Rmat = [t*Rx*Rx+cs,    t*Rx*Ry-sn*Rz, t*Rx*Rz+sn*Ry;
            t*Rx*Ry+sn*Rz, t*Ry*Ry+cs,    t*Ry*Rz-sn*Rx;
            t*Rx*Rz-sn*Ry, t*Ry*Rz+sn*Rx, t*Rz*Rz+cs   ];
    Vrev = (Rmat * Vrev').';

    bbr = max(Vrev)-min(Vrev);
    fprintf('    Bbox: %.2f x %.2f x %.2f m\n', bbr(1), bbr(2), bbr(3));

    grev = preprocessMesh(Frev, Vrev);
    rawR = computeRawRCSAzimuth(grev, k, lambda, thetaDeg, phiSweep, 'specular_area');
    rawR = max(rawR, 1e-30);

    % Calibrate so frontal = knownRCS (scale factor ≈ 1 since seed = computed frontal)
    frontalRaw = interp1(phiSweep, rawR, 90, 'linear', 'extrap');
    scaleR = revs(r).knownRCS / max(frontalRaw, 1e-40);
    calR   = rawR * scaleR;

    revs(r).calSigma = calR;
    revs(r).calDbsm  = 10*log10(max(calR, 1e-30));
    revs(r).frontal  = interp1(phiSweep, calR,  90, 'linear', 'extrap');
    revs(r).beam     = 0.5*(interp1(phiSweep, calR,   0, 'linear', 'extrap') + ...
                            interp1(phiSweep, calR, 180, 'linear', 'extrap'));
    revs(r).tail     = interp1(phiSweep, calR, 270, 'linear', 'extrap');
    revs(r).med      = median(calR);
end

sdbr = @(v) 10*log10(max(v,1e-30));
fprintf('\n  %-14s  %10s  %10s  %10s  %10s  %12s\n', ...
    'Revision','Frontal','Beam avg','Tail','Median','Beam/Frontal');
for r = 1:nRevs
    fprintf('  %-14s  %7.3f m^2  %7.3f m^2  %7.3f m^2  %7.3f m^2  %6.1fx (%+.1f dB)\n', ...
        revs(r).name, revs(r).frontal, revs(r).beam, revs(r).tail, revs(r).med, ...
        revs(r).beam/revs(r).frontal, sdbr(revs(r).beam)-sdbr(revs(r).frontal));
end

% --- Cartesian comparison ---
figure('Name','Hellstinger Revision Comparison');
hold on;
for r = 1:nRevs
    plot(phiSweep, revs(r).calDbsm, 'LineWidth', 2.0, 'Color', revs(r).color, ...
        'DisplayName', revs(r).name);
end
% Difference curve
diffDb = revs(2).calDbsm - revs(1).calDbsm;
yyaxis right;
plot(phiSweep, diffDb, ':', 'LineWidth', 1.2, 'Color', [0.9 0.7 0.1], ...
    'DisplayName', 'Delta V2-V1 (dB)');
ylabel('Delta RCS (dB)');
yline(0, '--', 'Color', [0.6 0.6 0.6], 'LineWidth', 0.8, 'HandleVisibility','off');
yyaxis left;
grid on;
xlabel('Azimuth phi (deg)  [phi=90: nose-on | phi=0,180: beam | phi=270: tail]');
ylabel('sigma (dBsm)');
title(sprintf('Hellstinger Revision Comparison (specular\\_area), f = %.1f GHz', f/1e9));
legend('Location', 'best');

% --- Polar comparison ---
allDbRev = cell2mat(arrayfun(@(x) x.calDbsm(:)', revs, 'UniformOutput', false));
gMinR = min(allDbRev(:)); gMaxR = max(allDbRev(:)); dRR = gMaxR - gMinR;
phiPlotR = deg2rad([phiSweep - 90, phiSweep(1) - 90]);

figure('Name','Hellstinger Revision Polar', 'Position', [200 100 700 700]);
paxR = polaraxes;
hold(paxR, 'on');

for r = 1:nRevs
    rhoR = [revs(r).calDbsm - gMinR, revs(r).calDbsm(1) - gMinR];
    lsR  = '-';
    if r == 1; lsR = '--'; end
    polarplot(paxR, phiPlotR, rhoR, lsR, 'LineWidth', 2.0, ...
        'Color', revs(r).color, 'DisplayName', revs(r).name);
end

paxR.ThetaZeroLocation = 'top';
paxR.ThetaDir          = 'clockwise';
paxR.GridColor         = [0.5 0.5 0.5];
paxR.GridAlpha         = 0.4;
nTR = 5; rTR = linspace(0, dRR, nTR);
paxR.RAxis.Limits = [0, dRR * 1.05];
paxR.RTick        = rTR;
paxR.RTickLabel   = arrayfun(@(v) sprintf('%+.0f dBsm', v + gMinR), ...
    rTR, 'UniformOutput', false);
paxR.ThetaTick      = [0 90 180 270];
paxR.ThetaTickLabel = {'Nose', 'Beam', 'Tail', 'Beam'};
title(sprintf('Hellstinger Revision Polar (specular\\_area), f = %.1f GHz', f/1e9), ...
    'FontSize', 11);
legend('Location', 'southoutside', 'NumColumns', nRevs);

% --- Bar chart comparison ---
figure('Name','Hellstinger Revision Metrics');
revNames = {revs.name};
metrics  = [[revs.frontal]; [revs.beam]; [revs.tail]; [revs.med]]';
metricDb = 10*log10(max(metrics, 1e-30));
X = categorical(revNames);
X = reordercats(X, revNames);
hbr = bar(X, metricDb, 'grouped');
for r = 1:nRevs
    hbr(r).FaceColor = revs(r).color;
end
ylabel('RCS (dBsm)');
legend({'Frontal','Beam avg','Tail','Median'}, 'Location', 'best');
grid on;
title('Hellstinger Revision Metrics (specular\_area)');
ylim([min(metricDb(:)) - 2, max(metricDb(:)) + 3]);
for bi = 1:numel(hbr)
    xpos = hbr(bi).XEndPoints;
    ypos = hbr(bi).YEndPoints;
    vals = hbr(bi).YData;
    for xi = 1:numel(xpos)
        text(xpos(xi), ypos(xi) + 0.3, sprintf('%.1f', vals(xi)), ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
            'FontSize', 8, 'Color', 'w');
    end
end


%% ================================================================
%%  LOCAL FUNCTIONS
%% ================================================================

function geom = preprocessMesh(F, V)
    P1 = V(F(:,1),:);
    P2 = V(F(:,2),:);
    P3 = V(F(:,3),:);

    Ncross = cross(P2 - P1, P3 - P1, 2);
    A      = 0.5 * vecnorm(Ncross, 2, 2);

    nNorm  = vecnorm(Ncross, 2, 2);
    nHat   = Ncross ./ max(nNorm, 1e-30);

    C = (P1 + P2 + P3) / 3;

    geom.P1   = P1;
    geom.P2   = P2;
    geom.P3   = P3;
    geom.A    = A;
    geom.nHat = nHat;
    geom.C    = C;
end

function sigma = computeRawRCSAzimuth(geom, k, lambda, thetaDeg, phiSweep, poMode)
% Physical Optics monostatic RCS, horizontal cut.
%
% Modes:
%   'coherent'       Phase-accurate PO sum.
%   'incoherent'     Sum of (A_n*cosθ_n)^2; rough-surface assumption.
%   'projected_area' sigma = sum A_n*cosθ_n; GO diffuse limit.
%   'specular_area'  sigma = sum A_n*cos^2(θ_n); captures shaping.
%
% RAM is applied externally as a uniform dB scaling per model (ram_dB field),
% which preserves polar shape. The Leontovich Z_s model was removed because
% angle-dependent absorption changes the polar shape, which is misleading
% for a uniform broadband coating specification.

    useCoherent  = strcmpi(poMode, 'coherent');
    useProjArea  = strcmpi(poMode, 'projected_area');
    useSpecArea  = strcmpi(poMode, 'specular_area');

    nPhi  = numel(phiSweep);
    sigma = zeros(1, nPhi);
    th    = deg2rad(thetaDeg);
    prefactor = 4 * pi / lambda^2;

    for i = 1:nPhi
        ph   = deg2rad(phiSweep(i));
        sHat = [sin(th)*cos(ph), sin(th)*sin(ph), cos(th)];

        ndotS    = geom.nHat * sHat.';
        lit      = (ndotS < 0);
        if ~any(lit); continue; end

        cosTheta = -ndotS(lit);
        weights  = geom.A(lit) .* cosTheta;

        if useSpecArea
            sigma(i) = sum(weights .* cosTheta);
        elseif useProjArea
            sigma(i) = sum(weights);
        elseif useCoherent
            phase    = exp(-1j * 2 * k * (geom.C(lit,:) * sHat.'));
            S        = sum(weights .* phase);
            sigma(i) = prefactor * abs(S)^2;
        else
            sigma(i) = prefactor * sum(weights.^2);
        end
    end
end


function [F, V] = stlReadSimple(filename)
    fid = fopen(filename, 'r');
    assert(fid > 0, 'Could not open STL: %s', filename);

    fseek(fid, 80, 'bof');
    numTri   = fread(fid, 1, 'uint32');
    fileInfo = dir(filename);
    isBinary = (fileInfo.bytes == 84 + numTri * 50);
    frewind(fid);

    if isBinary
        fread(fid, 80, 'uint8');
        numTri = fread(fid, 1, 'uint32');
        Vraw   = zeros(numTri*3, 3);
        F      = reshape(1:(numTri*3), 3, []).';

        for t = 1:numTri
            fread(fid, 3, 'float32');          % normal (ignored)
            v1 = fread(fid, 3, 'float32')';
            v2 = fread(fid, 3, 'float32')';
            v3 = fread(fid, 3, 'float32')';
            fread(fid, 1, 'uint16');           % attribute bytes

            idx = (t-1)*3 + 1;
            Vraw(idx,:)   = v1;
            Vraw(idx+1,:) = v2;
            Vraw(idx+2,:) = v3;
        end
        fclose(fid);
    else
        % ASCII STL
        txt   = textscan(fid, '%s', 'Delimiter', '\n');
        fclose(fid);
        lines = txt{1};
        verts = [];
        for i = 1:numel(lines)
            line = strtrim(lines{i});
            if startsWith(line, 'vertex')
                parts = sscanf(line, 'vertex %f %f %f');
                verts(end+1,:) = parts.'; %#ok<AGROW>
            end
        end
        assert(mod(size(verts,1), 3) == 0, 'ASCII STL parse failed: %s', filename);
        Vraw = verts;
        F    = reshape(1:size(Vraw,1), 3, []).';
    end


    % Deduplicate vertices
    [V, ~, ic] = unique(round(Vraw, 10), 'rows', 'stable');
    F = reshape(ic, 3, []).';
end

function result = analyzeNewModel(correction, stlFile, unitScale, rotAxis, rotDeg, modelName)
% analyzeNewModel  Apply fleet correction to a new aircraft STL.
%
% Usage:
%   result = analyzeNewModel(correction, 'myplane.stl', 0.001, [1 0 0], -90, 'My Aircraft')
%
% Inputs:
%   correction  - struct output from main script (contains fleet data)
%   stlFile     - path to new model STL
%   unitScale   - scale factor to convert STL units to meters
%   rotAxis     - [1x3] rotation axis to align fuselage to +Y
%   rotDeg      - rotation angle in degrees (0 = no rotation)
%   modelName   - display name string
%
% Method:
%   1) Compute raw incoherent PO sweep for the new model
%   2) Compute geometry similarity weights to each good comparator
%   3) Weighted-average the comparator correction scales (in dB)
%   4) Apply weighted correction to raw sweep
%   5) Report calibrated RCS with uncertainty bounds from comparator spread
%
% The uncertainty bound reflects how consistently the comparators agree —
% a tight fleet gives a narrower bound, a spread fleet gives a wider one.

    fprintf('\n======= New Model Analysis: %s =======\n', modelName);

    % Load and orient
    [F, V] = stlReadSimple(stlFile);
    V = V * unitScale;

    if rotDeg ~= 0
        ax  = rotAxis / norm(rotAxis);
        ang = deg2rad(rotDeg);
        c = cos(ang); s = sin(ang); t = 1-c;
        Rx=ax(1); Ry=ax(2); Rz=ax(3);
        R = [t*Rx*Rx+c,    t*Rx*Ry-s*Rz, t*Rx*Rz+s*Ry;
             t*Rx*Ry+s*Rz, t*Ry*Ry+c,    t*Ry*Rz-s*Rx;
             t*Rx*Rz-s*Ry, t*Ry*Rz+s*Rx, t*Rz*Rz+c   ];
        V = (R * V').';
    end

    bmin = min(V); bmax = max(V); bb = bmax - bmin;
    fprintf('Bounding box: Lx=%.2f m (span), Ly=%.2f m (length), Lz=%.2f m (height)\n', ...
        bb(1), bb(2), bb(3));

    geom = preprocessMesh(F, V);

    rawSigma = computeRawRCSAzimuth(geom, correction.k, correction.lambda, ...
        correction.thetaDeg, correction.phiSweep, correction.poMode);
    rawSigma = max(rawSigma, 1e-30);

    % Geometry feature vector for new model
    sa_new   = sum(geom.A) * 2;
    gv_new   = [log10(max(bb(1),1e-3)), log10(max(bb(2),1e-3)), log10(max(sa_new,1e-3))];

    % Geometry similarity weights to each good comparator
    goodIdx = correction.goodIdx;
    compModels = correction.models;
    nGood = numel(goodIdx);

    sigma_w = 1.0;   % width of Gaussian similarity kernel in log-space
    weights = zeros(1, nGood);
    scales_dB = zeros(1, nGood);

    fprintf('\nGeometry similarity to comparators:\n');
    for gi = 1:nGood
        m = goodIdx(gi);
        gv_m = compModels(m).geomVec;
        dist = norm(gv_new - gv_m);
        weights(gi) = exp(-dist^2 / (2 * sigma_w^2));
        scales_dB(gi) = 10*log10(compModels(m).scaleLin);
        fprintf('  %-30s  dist=%.3f  weight=%.3f  scale=%+.2f dB\n', ...
            compModels(m).name, dist, weights(gi), scales_dB(gi));
    end

    % Warn if new model is geometrically far from all comparators
    maxSim = max(weights);
    if maxSim < 0.1
        fprintf('\n  *** LOW SIMILARITY WARNING ***\n');
        fprintf('  Max comparator similarity = %.4f (< 0.1).\n', maxSim);
        fprintf('  New model geometry differs significantly from comparator fleet.\n');
        fprintf('  Correction transfer may be unreliable. Uncertainty bound is conservative.\n');
        % Widen uncertainty by geometry dissimilarity penalty
        dissimilarityPenalty_dB = -10*log10(max(maxSim, 1e-6)) * 0.5;
    else
        dissimilarityPenalty_dB = 0;
    end

    % Normalize weights
    if sum(weights) < 1e-12
        weights = ones(1, nGood) / nGood;
        fprintf('  Falling back to equal weights.\n');
    else
        weights = weights / sum(weights);
    end

    % Weighted correction and uncertainty (weighted std in dB)
    corrScale_dB  = sum(weights .* scales_dB);
    corrScale_std = sqrt(sum(weights .* (scales_dB - corrScale_dB).^2)) + dissimilarityPenalty_dB;
    corrScale_lin = 10^(corrScale_dB / 10);

    fprintf('\nApplied correction : %+.2f dB\n', corrScale_dB);
    fprintf('1-sigma uncertainty: +/-%.2f dB', corrScale_std);
    if dissimilarityPenalty_dB > 0
        fprintf('  (includes +%.2f dB geometry dissimilarity penalty)', dissimilarityPenalty_dB);
    end
    fprintf('\n');

    % Apply correction
    calSigma = rawSigma * corrScale_lin;
    calDbsm  = 10*log10(max(calSigma, 1e-30));

    % Upper/lower uncertainty bands
    calDbsm_hi = calDbsm + corrScale_std;
    calDbsm_lo = calDbsm - corrScale_std;

    % Extract aspect metrics
    ps = correction.phiSweep;
    frontal = interp1(ps, calSigma,  90, 'linear', 'extrap');
    beam    = 0.5*(interp1(ps, calSigma,   0, 'linear', 'extrap') + ...
                   interp1(ps, calSigma, 180, 'linear', 'extrap'));
    tail    = interp1(ps, calSigma, 270, 'linear', 'extrap');
    med     = median(calSigma);

    fprintf('\n---- Corrected RCS Estimates (%s) ----\n', modelName);
    sdb = @(v) 10*log10(max(v,1e-30));
    fprintf('  Frontal  : %8.3f m^2  (%+6.2f dBsm)  +/-%.1f dB\n', frontal, sdb(frontal), corrScale_std);
    fprintf('  Beam avg : %8.3f m^2  (%+6.2f dBsm)  +/-%.1f dB\n', beam,    sdb(beam),    corrScale_std);
    fprintf('  Tail     : %8.3f m^2  (%+6.2f dBsm)  +/-%.1f dB\n', tail,    sdb(tail),    corrScale_std);
    fprintf('  Median   : %8.3f m^2  (%+6.2f dBsm)  +/-%.1f dB\n', med,     sdb(med),     corrScale_std);

    % Cartesian plot with uncertainty band
    figure('Name', sprintf('New Model: %s', modelName));
    hold on;
    for gi = 1:nGood
        m = goodIdx(gi);
        plot(ps, compModels(m).calDbsm, '--', 'LineWidth', 1.0, ...
            'Color', [0.6 0.6 0.6], 'DisplayName', compModels(m).name);
    end
    fill([ps, fliplr(ps)], [calDbsm_hi, fliplr(calDbsm_lo)], ...
        [0.2 0.5 0.9], 'FaceAlpha', 0.2, 'EdgeColor', 'none', ...
        'DisplayName', sprintf('+/-%.1f dB uncertainty', corrScale_std));
    plot(ps, calDbsm, 'LineWidth', 2.0, 'Color', [0.2 0.5 0.9], ...
        'DisplayName', modelName);
    grid on;
    xlabel('Azimuth phi (deg)  [phi=90: nose-on | phi=0,180: beam | phi=270: tail]');
    ylabel('sigma (dBsm)');
    title(sprintf('Corrected RCS: %s vs Comparators', modelName));
    legend('Location', 'best');

    % Flower polar plot
    figure('Name', sprintf('Polar: %s', modelName), ...
        'Position', [150 150 700 700]);
    pax2 = polaraxes;
    hold(pax2, 'on');
    allDb = calDbsm;
    for gi = 1:nGood
        allDb = [allDb, compModels(goodIdx(gi)).calDbsm]; %#ok<AGROW>
    end
    gMin = min(allDb); gMax = max(allDb); dR = gMax - gMin;
    phi2 = deg2rad([ps - 90, ps(1) - 90]);
    for gi = 1:nGood
        m = goodIdx(gi);
        rho2 = [compModels(m).calDbsm - gMin, compModels(m).calDbsm(1) - gMin];
        polarplot(pax2, phi2, rho2, '--', 'LineWidth', 1.2, ...
            'Color', [0.6 0.6 0.6], 'DisplayName', compModels(m).name);
    end
    rhoNew = [calDbsm - gMin, calDbsm(1) - gMin];
    polarplot(pax2, phi2, rhoNew, 'LineWidth', 2.2, 'Color', [0.2 0.5 0.9], ...
        'DisplayName', modelName);
    pax2.ThetaZeroLocation = 'top';
    pax2.ThetaDir = 'clockwise';
    nT = 5; rT = linspace(0, dR, nT);
    pax2.RAxis.Limits = [0, dR*1.05];
    pax2.RTick = rT;
    pax2.RTickLabel = arrayfun(@(v) sprintf('%+.0f dBsm', v+gMin), rT, 'UniformOutput', false);
    pax2.ThetaTick      = [0 90 180 270];
    pax2.ThetaTickLabel = {'Nose', 'Beam', 'Tail', 'Beam'};
    title(sprintf('Polar RCS: %s', modelName));
    legend('Location','southoutside','NumColumns', nGood+1);

    % Return result struct
    result.name         = modelName;
    result.calSigma_m2  = calSigma;
    result.calDbsm      = calDbsm;
    result.frontal_m2   = frontal;
    result.beam_m2      = beam;
    result.tail_m2      = tail;
    result.median_m2    = med;
    result.correction_dB  = corrScale_dB;
    result.uncertainty_dB = corrScale_std;
    result.phiSweep     = ps;
end