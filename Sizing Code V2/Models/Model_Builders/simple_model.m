clear; clc; close all;

% HOW TO MAKE A MODEL DEFENITION

% 1) You need to build 6 input objects (6 models: CD0, cost, CDW, CLa, CDi, PROP)
% 2) Each gets a function handle like @CD0_basic. These handles get an input object with geometry, condition, and settings
% 3) Finally, note ALL inputs. Anytime you access the constructors the input should be mentioned (or there will be strange behavior)
%    The simplest defenition is just the constructor path. This tells the model this variable is not vectorized, shoul not be preloaded for
%    interpolation. Don't need to have any settings calls mentioned (they should not be changed during the optimization loop)
% 4) If the input can be interpolated, it should have (path, true). The function handle must be able to reuturn an array of output data
% 5) Finally, the (res, limits) calls can be enabled to tell the moddel to "preload" as set of inputs
%    Note that the script keeps track of the other inputs. So if a non-interploated value is called it regenerates the lookup. 
%    So interpolation should be enabled for anything that wil be called multiple orders of magnitude more than the other values
%    The interpoation method can be changed from the default linear using the 4th argument

CD0_model = model_def( "CD0", @CD0_basic, [model_input("geometry.weights.empty"), model_input("geometry.ref_area")] );

COST_model = model_def( "cost", @unitcost_wrapper, [model_input("geometry.weights.empty", true, 50, [1E2 1E6]), model_input("geometry.input.kloc", true)] );

CDW_model = model_def( "CDW", @CDW_basic, [model_input("condition.M", false, 30, [0.3 2]), model_input("geometry.fuselage.max_area"), ...
    model_input("geometry.fuselage.length"), model_input("geometry.wing.le_sweep"),  model_input("geometry.fuselage.E_WD") ], 'makima' );

CLa_model = model_def( "CLa", @CLa_basic, [model_input("condition.M")] );

CDi_model = model_def( "CDi", @CDi_simple, [model_input("condition.CL"), model_input("geometry.wing.AR"), ...
    model_input("geometry.wing.le_sweep"), model_input("condition.M")] );

Prop_model = model_def( "PROP", @Prop_Raymer, [model_input("condition.M", false, 10, [0.3 1.5]), model_input("condition.h", false, 10, [0 10000])]);

models = models_class([CD0_model COST_model CDW_model CLa_model CDi_model Prop_model]);

build_models_file(models, "simple_model")