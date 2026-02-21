tic;

initialize
matlabSetup

% Can try different models to make sure they are all vectorized
settings = readSettings();
geom = loadAircraft("f18_superhornet", settings);
geom = setLoadout(geom, ["AIM-9X" "" "" "AIM-120" "AIM-120" "" "" "AIM-9x"]);

% Set the condition
% cond = generateCondition(geom, 1000, 0.8, 1.7, 0.5, 1);
N = 100;
cond = generateCondition(geom, ...
    linspace(0, 5000, N), ... % Altitude
    linspace(0.5, 2, N), ... % Mach Number
    linspace(1, 2, N), ... % Load Factor
    linspace(0, 1, N), ... % Weight
    linspace(0.5, 1, N)); % Throttle

model = model_class(settings, geom, cond);
perf = performance_class(model);

fprintf("Setup took %.3g ms. \n\n", toc)

fprintf("COST | %s\n", do_check( @() model.COST, N) );
fprintf("CDw | %s\n", do_check( @() model.CDw, N) );
fprintf("CLa | %s\n", do_check( @() model.CLa, N) );
fprintf("CDi | %s\n", do_check( @() model.CDi, N) );
fprintf("CDp | %s\n", do_check( @() model.CDp, N) );
fprintf("SpotFactor | %s\n", do_check( @() model.SpotFactor, N) );
fprintf("CD | %s\n", do_check( @() perf.CD, N) );
fprintf("LD | %s\n", do_check( @() perf.LD, N) );
fprintf("Drag | %s\n", do_check( @() perf.Drag, N) );
fprintf("Lift | %s\n", do_check( @() perf.Lift, N) );
fprintf("TA | %s\n", do_check( @() perf.TA, N) );
fprintf("TSFC | %s\n", do_check( @() perf.TSFC, N) );
fprintf("alpha | %s\n", do_check( @() perf.alpha, N) );
fprintf("mdotf | %s\n", do_check( @() perf.mdotf, N) );
fprintf("ExcessThrust | %s\n", do_check( @() perf.ExcessThrust, N) );
fprintf("ExcessPower | %s\n", do_check( @() perf.ExcessPower, N) );
fprintf("TurnRate | %s\n", do_check( @() perf.TurnRate, N) );
fprintf("LevelTurnRate | %s\n", do_check( @() perf.LevelTurnRate, N) );
fprintf("ClimbAngle | %s\n", do_check( @() perf.ClimbAngle, N) );
fprintf("mdotf | %s\n", do_check( @() perf.mdotf, N) );

function res = do_check(fun_call, N)
    tic;
    try
        output = fun_call();

        if isequal(size(output), [1, N])
            res = sprintf("SUCCESS : %.3g microseconds / call", toc * 1E6 / N);
        else
            res = "INCORRECT DIM";
        end
    catch
        res = "NOT VECTORIZED - ERRORED";
        toc;
    end
end
