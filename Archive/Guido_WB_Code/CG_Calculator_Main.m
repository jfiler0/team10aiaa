%% CG_Calculator_Main
% The goal of this code is to calculate the center of gravity (CG) of each
% fighter concept.
% The CG_Location code utilizes the METRIC system.

%%
%%
%% Current Needs

% I need to determine the xstart vector for each wing, vertical tail, and
% horizontal tail.

% I need to know if I should scale based on the fuselage length or the
% total length of the aircraft. Some of the aircraft have tails that may
% reach behind the end of the fuselage.

% I will also need fuel tank locations to form potato diagrams. This I will
% do myself.

% If there are any major changes the the wing thickness, that will be
% important to be notified of.

clear;
clc;
close all;

%%
%%
%%


% This code utilizes the CG_Location function. Each fighter requires its
% own inputs and will produce their own outputs as follows:

%% Inputs for CG_Location
% For each concept, input the following parameters:
% S_exposed; for wings and tails
% S_wet; for fuselage
% c; vector of chord lengths [wing_chord, horizontal_tail_chord, vertical_tail_chord, fuselage_length]
% xstart; vector of starting location of each part of the aircraft [wing,
% horizontal tail, vertical tail, fuselage], important to note that the
% fuselage component should be 0.
% W_engine; engine weight

%% Outputs for CG_location
% xcg_estimate; the center of gravity for the aircraft
% W_vector; vector of weight estimates for each part of fighter
%       [W_wing, W_hTail, W_vTail, W_fuselage, W_nose_landing, W_main_landing, W_all_else_empty, W_engine]
% CG_vector; vector of each center of gravity for each part of the fighter
%       [xcg_wing, xcg_hTail, xcg_vTail, xcg_fuselage, xcg_nose_landing, xcg_main_landing, xcg_all_else_empty, xcg_engine]

%% General Assumptions for now

% Assumption 1
% We are assuming worst case scenario for the engine at 4000 lbs, or 1814
% kg. This is all from our savior Kevin

W_engine_all = 1814.36948; % kg

% Assumption 2
% This is a temporary assumption. Assume the TOGW of each concept is the
% same as the F-18 TOGW.

TOGW_temp = 16800; %kg

% Note 1
% Currently all the geometries are with respect to "units" in OPENVSP
% Must adjust values for input geometry.

% Note 2
% Jeffrey is a GOAT and lowkey made all the OPENVSP models in meters
% already. Esh-get-it

%% Definition of Concept 1

% Define the input variables
S_exposed_Concept1 = 6.10285; %units^2
S_wet_Concept1 = 52.1061; %unit^2
W_engine_Concept1 = W_engine_all;
TOGW_Concept1 = TOGW_temp;
c_Concept1 = [5.02027,1.71569,1.83514, 12.5]; % vector of chord lengths; [wing_chord, horizontal_tail_chord, vertical_tail_chord, fuselage_length]
xstart_Concept1 = [2.042,  6.607+2.055, 6.148+2.050, 0]; %[wing, horizontal tail, vertical tail, fuselage]

% Run function
[xcg_estimate_Concept1,W_vector_Concept1,CG_vector_Concept1] = CG_Location(S_exposed_Concept1,S_wet_Concept1,W_engine_Concept1,TOGW_Concept1,c_Concept1,xstart_Concept1);

%% Definition of Concept 2

% Define the input variables
S_exposed_Concept2 = 4.33528;
S_wet_Concept2 = 63.1704;
W_engine_Concept2 = W_engine_all;
TOGW_Concept2 = TOGW_temp;
c_Concept2 = [4.49963, 0, 2.48899,14.8];
xstart_Concept2 = [1.803,0,6.557+3.197,0];

% Run function
[xcg_estimate_Concept2,W_vector_Concept2,CG_vector_Concept2] = CG_Location(S_exposed_Concept2,S_wet_Concept2,W_engine_Concept2,TOGW_Concept2,c_Concept2,xstart_Concept2);

%% Definition of Concept 3

% Define the input variables
S_exposed_Concept3 = 5.93345;
S_wet_Concept3 = 67.203;
W_engine_Concept3 = W_engine_all;
TOGW_Concept3 = TOGW_temp;
c_Concept3 = [4.73595,1.46373,2.26171,14.14054];
xstart_Concept3 = [5.902,4.038,10.049,0];

% Run function
[xcg_estimate_Concept3,W_vector_Concept3,CG_vector_Concept3] = CG_Location(S_exposed_Concept3,S_wet_Concept3,W_engine_Concept3,TOGW_Concept3,c_Concept3,xstart_Concept3);

%% Definition of Concept 4

% Define the input variables
S_exposed_Concept4 = 5.85298;
S_wet_Concept4 = 61.4487;
W_engine_Concept4 = W_engine_all;
TOGW_Concept4 = TOGW_temp;
c_Concept4 = [4.01158,2.27348,2.59578,15.00000];
xstart_Concept4 = [4.280,11.409,10.848,0];

% Run function
[xcg_estimate_Concept4,W_vector_Concept4,CG_vector_Concept4] = CG_Location(S_exposed_Concept4,S_wet_Concept4,W_engine_Concept4,TOGW_Concept4,c_Concept4,xstart_Concept4);

%% Definition of Concept 5

% Define the input variables
S_exposed_Concept5 = 6.57962;
S_wet_Concept5 = 73.4139;
W_engine_Concept5 = W_engine_all;
TOGW_Concept5 = TOGW_temp;
c_Concept5 = [4.99096,2.27348,2.59578,13.20958];
xstart_Concept5 = [4.280,13.829,12.300,0];

% Run function
[xcg_estimate_Concept5,W_vector_Concept5,CG_vector_Concept5] = CG_Location(S_exposed_Concept5,S_wet_Concept5,W_engine_Concept5,TOGW_Concept5,c_Concept5,xstart_Concept5);

%% Definition of Concept 6

% Define the input variables
S_exposed_Concept6 = 7.12826;
S_wet_Concept6 = 60.8934;
W_engine_Concept6 = W_engine_all;
TOGW_Concept6 = TOGW_temp;
c_Concept6 = [4.69820,0,1.41733,8.56869];
xstart_Concept6 = [0,0,6.432,0];

% Run function
[xcg_estimate_Concept6,W_vector_Concept6,CG_vector_Concept6] = CG_Location(S_exposed_Concept6,S_wet_Concept6,W_engine_Concept6,TOGW_Concept6,c_Concept6,xstart_Concept6);

%% Definition of Comparator Aircraft F-16

% Define the input variables
S_exposed_Comparator1 = 4.95848;
S_wet_Comparator1 = 60.128;
W_engine_Comparator1 = W_engine_all;
TOGW_Comparator1 = TOGW_temp;
c_Comparator1 = [4.76507,2.21096,2.48899,14.8];
xstart_Comparator1 = [1.803, 11.711, 9.59, 0];

% Run function
[xcg_estimate_Comparator1,W_vector_Comparator1,CG_vector_Comparator1] = CG_Location(S_exposed_Comparator1,S_wet_Comparator1,W_engine_Comparator1,TOGW_Comparator1,c_Comparator1,xstart_Comparator1);

%% Definition of Comparator Aircraft F-18E

% Define the input variables
S_exposed_Comparator2 = 7.05732;
S_wet_Comparator2 = 81.6068;
W_engine_Comparator2 = W_engine_all;
TOGW_Comparator2 = TOGW_temp;
c_Comparator2 = [4.88065, 2.49096, 2.59578, 17.54071];
xstart_Comparator2 = [4.28, 13.622, 12.162, 0];

% Run function
[xcg_estimate_Comparator2,W_vector_Comparator2,CG_vector_Comparator2] = CG_Location(S_exposed_Comparator2,S_wet_Comparator2,W_engine_Comparator2,TOGW_Comparator2,c_Comparator2,xstart_Comparator2);

%% End of Code