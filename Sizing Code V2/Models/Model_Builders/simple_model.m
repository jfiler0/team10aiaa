clear; clc; close all;

CD0_model = model_def( "CD0", @CD0_basic, [model_input("geometry.weights.empty", false), model_input("geometry.ref_area", false)] );

COST_model = model_def( "cost", @unitcost_wrapper, [model_input("geometry.weights.empty", true, 50, [1E2 1E6]), model_input("geometry.input.kloc", true, 1)] );

CDW_model = model_def( "CDW", @CDW_basic, [model_input("condition.M", false, 30, [0.3 2]), model_input("geometry.fuselage.max_area", false, 1), ...
    model_input("geometry.fuselage.length", false, 1), model_input("geometry.wing.le_sweep", false, 1),  model_input("geometry.fuselage.E_WD", false, 1) ], 'makima' );

CLa_model = model_def( "CLa", @CLa_basic, [model_input("condition.M", false)] );

CDi_model = model_def( "CDi", @CDi_simple, [model_input("condition.CL", false), model_input("geometry.wing.AR", false, 1), ...
    model_input("geometry.wing.le_sweep", false, 1)] );

Prop_model = model_def( "PROP", @Prop_Raymer, [model_input("condition.M", false, 10, [0.3 1.5]), model_input("condition.h", false, 10, [0 10000])]);

models = models_class([CD0_model COST_model CDW_model CLa_model CDi_model Prop_model]);

build_models_file(models, "simple_model")