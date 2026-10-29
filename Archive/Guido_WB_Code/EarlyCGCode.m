%% Early Concept Center of Gravity Code

%% Inputs
% For each concept, input the following parameters:
% S_exposed; for wings and tails
% S_wet; for fuselage
% c; vector of chord lengths [wing_chord, horizontal_tail_chord, vertical_tail_chord, fuselage_length]
% W_engine; engine weight






%% Function Code

function [xcg_estimate,W_vector,CG_vector] = CG_Location(S_exposed,S_wet,W_engine,TOGW,c)

%% Step 1 and Step 2
% First, seperate the weight into 7 different sections. Wing, horizontal
% tail, vertical tail, fuselage, landing gear, engine, and all else empty.

% Utilize Raymer Table to draw estimates for WS and weight ratios.

% Table 15.2 from Raymer data for Fighters
% Approximate Empty Weight Buildup

wing_WS = 44; %kg/m^2, multuply by S_exposed
hTail_WS = 20; %kg/m^2, multuply by S_exposed
vTail_WS = 26; %kg/m^2, multuply by S_exposed
fuselage_WS = 23; %kg/m^2, multuply by S_wet

nose_landing_WS = 0.033; %multiply by TOGW
main_landing_WS = 0.045; %multiply by TOGW
engine_WS = 1.3; %multiply by engine weight

all_else_empty = 0.17; %multiply by TOGW

%% Step 3
% Determine the position of the aircraft CG. The sum of each section
% multiplied by its xcg location divided by the sum of each section's
% weights gives a good estimate for the aircraft CG.

%calculate weight of each segment
W_wing = wing_WS *S_exposed;
W_hTail = hTail_WS * S_exposed;
W_vTail = vTail_WS * S_exposed;
W_fuselage = fuselage_WS * S_wet;
W_nose_landing = nose_landing_WS*TOGW;
W_main_landing = main_landing_WS*TOGW;
W_all_else_empty = all_else_empty*TOGW;

%estimate of cg locations
% from Raymer
xcg_wing = 0.4*c(1); % 40% of MAC
xcg_hTail = 0.4*c(2); % 40% of MAC
xcg_vTail = 0.4*c(3); % 40% of MAC
xcg_fuselage = 0.5*c(4); %located approximately in the fuselage center.
xcg_all_else_empty = 0.5*c(4); %located approximately in the middle of the fuselage.

% Need to adjust the xcg for the wings and tails to be relative to the
% fuselage length.
%%% Will do this later (will probably have an input vector for the start
%%% and end location of each of these parts.






% Raymer assumes the centroids of the engine and landing gears are their
% respective locations of cg.

%%% For now, I will assume the front landing gear CG is located at 15% of the
%%% fuselage length, the main landing gear CG is located at 65% of the fuselage
%%% length, and the engine CG is located at 85% of the fuselage length

xcg_engine = 0.85*c(4);
xcg_nose_landing = 0.15*c(4);
xcg_main_landing = 0.65*c(4);



%make vectors for easier calculations.
%vector of weights
W_vector = [W_wing,W_hTail,W_vTail,W_fuselage,W_nose_landing,W_main_landing,W_all_else_empty];
%vector of CGs
CG_vector = [xcg_wing,xcg_hTail,xcg_vTail,xcg_fuselage,xcg_nose_landing,xcg_main_landing,xcg_all_else_empty];

%summation calculations
WiCG_product = 0;
for i = 1:length(W_vector)
    WiCG_product_temp = W_vector(i)*CG_vector(i);
    WiCG_product = WiCG_product+WiCG_product_temp;
end

Wi_sum = sum(W_vector);

xcg_estimate = WiCG_product/Wi_sum;

%% Step 4
% Tabulate weights, cgs, and moments (x-,y-,and z-) for each weight group


end