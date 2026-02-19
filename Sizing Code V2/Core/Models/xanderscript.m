
%% Detailed Cost
% Walks through Roskam Book VIII Chapters 3,4,6,7
% For questions, ask Xander
close all;
%% TODO:
% avionics estimated to be 30% of AEP cost (Appendix C says 5-40) - line 47
% Section 6: revisit depot costs bc we're on a carrier - line 166          

%% Aircraft-Dependent Inputs
W_ampr=35500; %lb (kinda like empty weight)
W_TO=66000; %lb
% W_ampr=10^(0.1936+0.8645*log10(W_TO)); this is what Roskam wants but seems to be a poor estimate
V_max= 563; % knots (max level military). 563 is M0.85 @SL
C_e_r= 3.5e6*CER(2025)/CER(1991); %cost per engine (F100-3.5 in 1991 & F414-4.86 in 2025)
N_e=2; % number of engines per plane
W_F_used=36000; % fuel used in lbs per mission
t_mis=3; % number of hours per mission
KLOC=9000;

%% Hardcoded Inputs
N_m=500; % number of aircraft produced during the production run
N_rdte=8; % number of test aircraft (static and flight). recommended 6-20 for military, but we're close to F-18 already
N_program=N_m+N_rdte;
F_diff=1.5; % trying to keep advanced technologies down to meet Augustine's law
F_cad=0.8; % experienced CAD manufacturers
R_e_r= 76*CER(2025)/CER(1989); % engineering hourly rate. accounts for additional costs of a secret military program
C_p_r=0; %cost per propeller;
N_p=0; % number of propellers per airplane
N_st=2;%number of static test aircraft
R_m_r= 42*CER(2025)/CER(1989);%manufacturing hourly rate. accounts for secret
F_mat=2; %material scaling factor (2-2.5 for composites)
N_r_r=0.33; %RDTE production rate in units per month. std 0.33
N_r_m=500/10/12; %production rate per month.
R_t_r=54*CER(2025)/CER(1989); %tooling hourly rate. accounts for secret
F_obs=3; % stealth requirement factor (page 34)

%% Sec 3 RDTE

% Sec 3.1 Airframe Engineering and Design Cost
MHR_aed_r=0.0396*W_ampr^0.791*V_max^1.526*N_rdte^0.183*F_diff*F_cad; %engineering hours
C_aed_r=MHR_aed_r*R_e_r; % inflation accounted for in R_E_r

% Sec 3.2 Dev Support and Testing Cost
C_dst_r=0.008325*W_ampr^0.873*V_max^1.890*N_rdte^0.346*CER(2025)*F_diff;

% Sec 3.3 Flight Test Airplanes Cost
C_avionics=0.3/0.7*(51.813e6); % TODO: update per iteration to get 30% of AEP
C_eANDr_r = (C_e_r*N_e+C_p_r*N_p+C_avionics)*(N_rdte-N_st);
MHR_man_r=28.984*W_ampr^0.74*V_max^0.543*N_rdte^0.524*F_diff; % manufacturing manhours
C_man_r=MHR_man_r*R_m_r; %manufacturing labor cost
C_mat_r   = 37.632*F_mat*W_ampr^0.689*V_max^0.624*N_rdte^0.792*CER(2025); %material costs
MHR_tool_r=4.0127*W_ampr^0.764*V_max^0.899*N_rdte^0.178*N_r_r^0.066*F_diff;
C_tool_r = MHR_tool_r * R_t_r; % tooling costs based on manufacturing hours and rate
C_qc_r= 0.13*C_man_r; %quality control costs
C_fta_r=C_eANDr_r+C_man_r+C_mat_r+C_tool_r+C_qc_r;

% Sec 3.4 Flight Test Operations Cost
C_fto_r=0.001244*W_ampr^1.16*V_max^1.371*(N_rdte-N_st)^1.281*CER(2025)*F_diff*F_obs;

% Sec 3.5 Test and Simulation Facilities Cost
%this expense is for any extra facilities or software need to be developed
%to test the aircraft (page 35). Suggested range is 0 to 20%. This factor
%will be applied at the end
F_tsf=0.1;

% Sec 3.6 RDTE Profit
%will be applied at the end as a percent of RDTE cost. Roskam suggests 10%
%for commercial, but I'm pretty sure military limits profits in a clause.
F_pro_r=0.08;

% Sec 3.7 Financing RDTE Phase
C_fin_r=0; % cost to finance - I don't think this applies for military programs

% Extra Sec: Software (from COCOMO)
% KLOC = thousands of lines of code
a=3.6;
b=1.2; % fighters typically use embedded systems
E = a*KLOC^b; % in person months
cost_software=E*16000; 
% 16,000 per person per month from COCOMO II (2013)
C_soft=cost_software*CER(2025)/CER(2013); % inflation

% Final RDTE
C_RDTE=(C_aed_r+C_dst_r+C_fta_r+C_fto_r+C_fin_r+C_soft)/(1-F_tsf-F_pro_r);
C_tsf_r=C_RDTE*F_tsf; % accounts for sec 3.5
C_pro_r=C_RDTE*F_pro_r; % accounts for RDTE profit

%% Sec 4 Manufacturing and Aquisition Cost
N_acq=N_program;

% Manufacturing Cost
% 4.1 Airframe Engineering and Design Cost
R_e_m=R_e_r;
MHR_aed_program=0.0396*W_ampr^0.791*V_max^1.526*N_program^0.183*F_diff*F_cad;
C_aed_m= MHR_aed_program*R_e_m-C_aed_r;

% 4.2 Airplane Production Cost
C_e_m=C_e_r; % cost per engine. same as RDTE bc COTS
C_p_m=0; % cost per propeller
C_avionics_m=C_avionics; % avionics cost
C_eANDr_m=(C_e_m*N_e+C_p_m*N_p+C_avionics_m)*N_m;
C_int_m=0; % cost of airplane interior. 0 for military
R_m_m=R_m_r;
MHR_man_program=28.984*W_ampr^0.74*V_max^0.543*N_program^0.524*F_diff; % manufacturing manhours
C_man_m=MHR_man_program*R_m_m-C_man_r;
C_mat_program=37.632*F_mat*W_ampr^0.689*V_max^0.624*N_program^0.792*CER(2025);
C_mat_m=C_mat_program-C_mat_r;
R_t_m=R_t_r;
MHR_tool_program=4.0127*W_ampr^0.764*V_max^0.899*N_program^0.178*N_r_m^0.066*F_diff;
C_tool_m=MHR_tool_program*R_t_m-C_tool_r;
C_qc_m=0.13*C_man_m;
C_apc_m = C_eANDr_m + C_int_m + C_man_m + C_mat_m + C_tool_m + C_qc_m;

% 4.3 Production Flight Test Operations Cost
F_ftoh=4; % overhead factor for flight test activities
t_pft=20; % number of flight test hours flown before delivery
C_opshr=2.6556e4; % got this by running the code on an arbitrary value and fixing with to C_opshr2 after
C_fto_m=N_m*C_opshr*t_pft*F_ftoh;

% 4.4 Cost of financing manufacturing program
C_fin_m=0; % 0 for military?

C_MAN=C_aed_m+C_apc_m+C_fto_m+C_fin_m;

% 4.5 Profit from Production
F_pro_m=F_pro_r;
C_PRO=F_pro_m*C_MAN;

C_ACQ=C_MAN+C_PRO;
AEP=(C_ACQ+C_RDTE)/N_m; % unit price per airplane

%% Sec 6: Operating Cost of Military Airplanes

% Sec 6.1 Program Fuel, Oil and Lubricants Cost
F_OL=1.005;
FP=6.30; % Jet A price: 2025 US dollars per gallon (globalair.com)
FD=0.81; %g/cm^3
FD=FD*8.345404; % lb/gallon
U_ann_flt=350; % number of hours flown per year per aircraft (Table 6.1)
N_mission=U_ann_flt/t_mis; % number of missions flown per year
N_res=0.1*N_acq; % reserve aircraft
N_yr=8000/U_ann_flt; % 8000 hour lifetime (Bob)
L_R=2/100000; % loss rate for F-18 for Navy from Table 6.2
N_serv=(N_acq-N_res)/(1+0.5*L_R*U_ann_flt*N_yr);
N_loss=L_R*N_serv*U_ann_flt*N_yr;
C_POL=F_OL*W_F_used*FP/FD*N_mission*N_serv*N_yr;

% Sec 6.2 Direct Personnel Cost
N_crew=1; % single pilot
R_cr=1.1; % crew ratio for fighter
Pay_crew=(29286+12*400+11000)*CER(2025)/CER(1989);
OHR_crew=3; % overhead rate
C_crewpr=N_serv*N_crew*R_cr*Pay_crew*OHR_crew*N_yr; % crew 
R_m_ml=45*CER(2025)/CER(1989); % maintance labor rate
MHR_flthr= 20; % maintance hours per flight hour (15-35 for fighters)

C_mpersdir=N_serv*N_yr*U_ann_flt*MHR_flthr*R_m_ml; % direct maintaince peeps
C_PERSDIR=C_crewpr+C_mpersdir; 

% Sec 6.3 Indirect Personnel Cost
%added at the end
f_persind=0.20; % F-4 from Table 6.6

% Sec 6.4 Consumable Materials for Maintanence
R_conmat=6.5*CER(2025)/CER(1989); % cost per hour for consumable materials
C_CONMAT=N_serv*N_yr*U_ann_flt*MHR_flthr*R_conmat; 

% Sec 6.5 Spares
% added at the end
f_spares=0.12;


% Sec 6.6 Depots
% added at the emd
f_depot=0.10;  

% Sec 6.7 Misc
C_MISC=4*C_CONMAT;

C_OPS=(C_POL+C_PERSDIR+C_CONMAT+C_MISC)/(1-f_persind-f_spares-f_depot);
C_opshr2=C_OPS/(N_serv*8000); % 8000 is lifetime hours = N_yr*U_ann_flt
C_PERSIND=C_OPS*f_persind;
C_SPARES=C_OPS*f_spares;
C_DEPOT=f_depot*C_OPS;

%% Sec 7 Life Cycle Costs

% 7.4 Disposal
f_disp=0.01;

% everything else was found already

LCC=(C_RDTE+C_ACQ+C_OPS)/(1-f_disp); %life cycle cost (Eq. 2.3)
C_DISP=LCC*f_disp;

%% =====================================================================
%% CREATE FORMATTED TABLES
%% =====================================================================

fprintf('\n');
fprintf('╔══════════════════════════════════════════════════════════════════════════════╗\n');
fprintf('║                      AIRCRAFT COST ANALYSIS SUMMARY                          ║\n');
fprintf('╚══════════════════════════════════════════════════════════════════════════════╝\n\n');

% ----- RDTE Cost Table -----
fprintf('┌──────────────────────────────────────────────────────────────────────────────┐\n');
fprintf('│                         RDTE COST BREAKDOWN                                  │\n');
fprintf('├──────────────────────────────────────────────────────┬───────────┬───────────┤\n');
fprintf('│ Category                                             │  Cost ($M)│  Percent  │\n');
fprintf('├──────────────────────────────────────────────────────┼───────────┼───────────┤\n');
fprintf('│ Airframe Engineering & Design                        │ %9.2f │ %7.2f%% │\n', C_aed_r/1e6, C_aed_r/C_RDTE*100);
fprintf('│ Development Support & Testing                        │ %9.2f │ %7.2f%% │\n', C_dst_r/1e6, C_dst_r/C_RDTE*100);
fprintf('│ Flight Test Airplanes                                │ %9.2f │ %7.2f%% │\n', C_fta_r/1e6, C_fta_r/C_RDTE*100);
fprintf('│   ├─ Engines & Avionics                              │ %9.2f │           │\n', C_eANDr_r/1e6);
fprintf('│   ├─ Manufacturing Labor                             │ %9.2f │           │\n', C_man_r/1e6);
fprintf('│   ├─ Materials                                       │ %9.2f │           │\n', C_mat_r/1e6);
fprintf('│   ├─ Tooling                                         │ %9.2f │           │\n', C_tool_r/1e6);
fprintf('│   └─ Quality Control                                 │ %9.2f │           │\n', C_qc_r/1e6);
fprintf('│ Flight Test Operations                               │ %9.2f │ %7.2f%% │\n', C_fto_r/1e6, C_fto_r/C_RDTE*100);
fprintf('│ Software Development (COCOMO)                        │ %9.2f │ %7.2f%% │\n', C_soft/1e6, C_soft/C_RDTE*100);
fprintf('│ Test & Simulation Facilities (%.0f%%)                   │ %9.2f │ %7.2f%% │\n', F_tsf*100, C_tsf_r/1e6, C_tsf_r/C_RDTE*100);
fprintf('│ RDTE Profit (%.0f%%)                                     │ %9.2f │ %7.2f%% │\n', F_pro_r*100, C_pro_r/1e6, C_pro_r/C_RDTE*100);
fprintf('├──────────────────────────────────────────────────────┼───────────┼───────────┤\n');
fprintf('│ TOTAL RDTE                                           │ %9.2f │   100.00%% │\n', C_RDTE/1e6);
fprintf('└──────────────────────────────────────────────────────┴───────────┴───────────┘\n\n');

% ----- Production/Acquisition Cost Table -----
fprintf('┌──────────────────────────────────────────────────────────────────────────────┐\n');
fprintf('│                    PRODUCTION/ACQUISITION COST BREAKDOWN                     │\n');
fprintf('├──────────────────────────────────────────────────────┬───────────┬───────────┤\n');
fprintf('│ Category                                             │  Cost ($M)│  Percent  │\n');
fprintf('├──────────────────────────────────────────────────────┼───────────┼───────────┤\n');
fprintf('│ Airframe Engineering & Design                        │ %9.2f │ %7.2f%% │\n', C_aed_m/1e6, C_aed_m/C_ACQ*100);
fprintf('│ Airplane Production Cost                             │ %9.2f │ %7.2f%% │\n', C_apc_m/1e6, C_apc_m/C_ACQ*100);
fprintf('│   ├─ Engines & Avionics                              │ %9.2f │           │\n', C_eANDr_m/1e6);
fprintf('│   ├─ Manufacturing Labor                             │ %9.2f │           │\n', C_man_m/1e6);
fprintf('│   ├─ Materials                                       │ %9.2f │           │\n', C_mat_m/1e6);
fprintf('│   ├─ Tooling                                         │ %9.2f │           │\n', C_tool_m/1e6);
fprintf('│   └─ Quality Control                                 │ %9.2f │           │\n', C_qc_m/1e6);
fprintf('│ Production Flight Test Operations                    │ %9.2f │ %7.2f%% │\n', C_fto_m/1e6, C_fto_m/C_ACQ*100);
fprintf('│ Production Profit (%.0f%%)                              │ %9.2f │ %7.2f%% │\n', F_pro_m*100, C_PRO/1e6, C_PRO/C_ACQ*100);
fprintf('├──────────────────────────────────────────────────────┼───────────┼───────────┤\n');
fprintf('│ TOTAL ACQUISITION                                    │ %9.2f │   100.00%% │\n', C_ACQ/1e6);
fprintf('├──────────────────────────────────────────────────────┼───────────┼───────────┤\n');
fprintf('│ Unit Price (AEP) for %d aircraft                     │ %9.2f │           │\n', N_m, AEP/1e6);
fprintf('└──────────────────────────────────────────────────────┴───────────┴───────────┘\n\n');

% ----- Operating Cost Table -----
fprintf('┌──────────────────────────────────────────────────────────────────────────────┐\n');
fprintf('│                        OPERATING COST BREAKDOWN                              │\n');
fprintf('│                     (%.0f years, %d service aircraft)                         │\n', N_yr, round(N_serv));
fprintf('├──────────────────────────────────────────────────────┬───────────┬───────────┤\n');
fprintf('│ Category                                             │  Cost ($M)│  Percent  │\n');
fprintf('├──────────────────────────────────────────────────────┼───────────┼───────────┤\n');
fprintf('│ Fuel, Oil & Lubricants                               │ %9.2f │ %7.2f%% │\n', C_POL/1e6, C_POL/C_OPS*100);
fprintf('│ Direct Personnel                                     │ %9.2f │ %7.2f%% │\n', C_PERSDIR/1e6, C_PERSDIR/C_OPS*100);
fprintf('│   ├─ Crew Personnel                                  │ %9.2f │           │\n', C_crewpr/1e6);
fprintf('│   └─ Maintenance Personnel                           │ %9.2f │           │\n', C_mpersdir/1e6);
fprintf('│ Indirect Personnel (%.0f%%)                             │ %9.2f │ %7.2f%% │\n', f_persind*100, C_PERSIND/1e6, C_PERSIND/C_OPS*100);
fprintf('│ Consumable Materials                                 │ %9.2f │ %7.2f%% │\n', C_CONMAT/1e6, C_CONMAT/C_OPS*100);
fprintf('│ Spares (%.0f%%)                                         │ %9.2f │ %7.2f%% │\n', f_spares*100, C_SPARES/1e6, C_SPARES/C_OPS*100);
fprintf('│ Depot Maintenance (%.0f%%)                              │ %9.2f │ %7.2f%% │\n', f_depot*100, C_DEPOT/1e6, C_DEPOT/C_OPS*100);
fprintf('│ Miscellaneous                                        │ %9.2f │ %7.2f%% │\n', C_MISC/1e6, C_MISC/C_OPS*100);
fprintf('├──────────────────────────────────────────────────────┼───────────┼───────────┤\n');
fprintf('│ TOTAL OPERATING                                      │ %9.2f │   100.00%% │\n', C_OPS/1e6);
fprintf('├──────────────────────────────────────────────────────┼───────────┼───────────┤\n');
fprintf('│ Cost per Flight Hour                                 │ %9.2f │           │\n', C_opshr2/1e3);
fprintf('│ (thousands $)                                        │           │           │\n');
fprintf('└──────────────────────────────────────────────────────┴───────────┴───────────┘\n\n');

% ----- Life Cycle Cost Table -----
fprintf('┌──────────────────────────────────────────────────────────────────────────────┐\n');
fprintf('│                       LIFE CYCLE COST BREAKDOWN                              │\n');
fprintf('├──────────────────────────────────────────────────────┬───────────┬───────────┤\n');
fprintf('│ Phase                                                │  Cost ($M)│  Percent  │\n');
fprintf('├──────────────────────────────────────────────────────┼───────────┼───────────┤\n');
fprintf('│ RDTE                                                 │ %9.2f │ %7.2f%% │\n', C_RDTE/1e6, C_RDTE/LCC*100);
fprintf('│ Acquisition                                          │ %9.2f │ %7.2f%% │\n', C_ACQ/1e6, C_ACQ/LCC*100);
fprintf('│ Operations                                           │ %9.2f │ %7.2f%% │\n', C_OPS/1e6, C_OPS/LCC*100);
fprintf('│ Disposal (%.0f%%)                                        │ %9.2f │ %7.2f%% │\n', f_disp*100, C_DISP/1e6, C_DISP/LCC*100);
fprintf('├──────────────────────────────────────────────────────┼───────────┼───────────┤\n');
fprintf('│ TOTAL LIFE CYCLE COST                                │ %9.2f │   100.00%% │\n', LCC/1e6);
fprintf('└──────────────────────────────────────────────────────┴───────────┴───────────┘\n\n');

%% =====================================================================
%% CREATE IMPROVED PIE CHARTS
%% =====================================================================

% Define custom colormaps for better visual separation
colors_rdte = [
    0.2039 0.5412 0.7412;   % Steel Blue
    0.8431 0.0980 0.1098;   % Crimson
    0.1725 0.6275 0.1725;   % Forest Green
    1.0000 0.4980 0.0000;   % Orange
    0.5804 0.4039 0.7412;   % Medium Purple
    0.8902 0.4667 0.7608;   % Orchid
    0.4980 0.4980 0.4980;   % Gray
];

colors_prod = [
    0.2039 0.5412 0.7412;   % Steel Blue
    0.8431 0.0980 0.1098;   % Crimson
    0.1725 0.6275 0.1725;   % Forest Green
    1.0000 0.4980 0.0000;   % Orange
    0.5804 0.4039 0.7412;   % Medium Purple
    0.8902 0.4667 0.7608;   % Orchid
    0.9373 0.8941 0.0784;   % Gold
    0.4980 0.4980 0.4980;   % Gray
];

colors_ops = [
    0.2039 0.5412 0.7412;   % Steel Blue
    0.8431 0.0980 0.1098;   % Crimson
    0.1725 0.6275 0.1725;   % Forest Green
    1.0000 0.4980 0.0000;   % Orange
    0.5804 0.4039 0.7412;   % Medium Purple
    0.8902 0.4667 0.7608;   % Orchid
    0.9373 0.8941 0.0784;   % Gold
];

colors_lcc = [
    0.2039 0.5412 0.7412;   % Steel Blue
    0.8431 0.0980 0.1098;   % Crimson
    0.1725 0.6275 0.1725;   % Forest Green
    1.0000 0.4980 0.0000;   % Orange
];

%% Figure 1: Summary Dashboard (2x2 layout)
figure('Position', [50, 50, 1400, 900], 'Color', 'white');
sgtitle('Aircraft Program Cost Analysis Summary', 'FontSize', 16, 'FontWeight', 'bold');

% ----- RDTE Pie Chart -----
subplot(2,2,1);
rdte_costs = [C_aed_r, C_dst_r, C_fta_r, C_fto_r, C_soft, C_tsf_r, C_pro_r];
rdte_labels = {'Airframe Eng', 'Dev Support', 'Flight Test A/C', ...
               'Flight Test Ops', 'Software', 'Test Facilities', 'Profit'};
rdte_pcts = rdte_costs/sum(rdte_costs)*100;

% Only show labels for slices > 5%
rdte_labels_display = cell(size(rdte_labels));
for i = 1:length(rdte_pcts)
    if rdte_pcts(i) >= 5
        rdte_labels_display{i} = sprintf('%s\n%.1f%%', rdte_labels{i}, rdte_pcts(i));
    else
        rdte_labels_display{i} = '';
    end
end

p1 = pie(rdte_costs, rdte_labels_display);
colororder(colors_rdte);
for i = 1:2:length(p1)
    p1(i).FaceColor = colors_rdte(ceil(i/2), :);
    p1(i).EdgeColor = 'white';
    p1(i).LineWidth = 1.5;
end
title(sprintf('RDTE Cost: $%.1fM', C_RDTE/1e6), 'FontSize', 12, 'FontWeight', 'bold');

% ----- Production Pie Chart -----
subplot(2,2,2);
prod_costs = [C_aed_m, C_eANDr_m, C_man_m, C_mat_m, C_tool_m, C_qc_m, C_fto_m, C_PRO];
prod_labels = {'Airframe Eng', 'Engines/Avionics', 'Mfg Labor', 'Materials', ...
               'Tooling', 'QC', 'Flight Test', 'Profit'};
prod_pcts = prod_costs/sum(prod_costs)*100;

prod_labels_display = cell(size(prod_labels));
for i = 1:length(prod_pcts)
    if prod_pcts(i) >= 3
        prod_labels_display{i} = sprintf('%s\n%.1f%%', prod_labels{i}, prod_pcts(i));
    else
        prod_labels_display{i} = '';
    end
end

p2 = pie(prod_costs, prod_labels_display);
for i = 1:2:length(p2)
    p2(i).FaceColor = colors_prod(ceil(i/2), :);
    p2(i).EdgeColor = 'white';
    p2(i).LineWidth = 1.5;
end
title(sprintf('Acquisition Cost: $%.1fM', C_ACQ/1e6), 'FontSize', 12, 'FontWeight', 'bold');

% ----- Operating Cost Pie Chart -----
subplot(2,2,3);
ops_costs = [C_POL, C_PERSDIR, C_PERSIND, C_CONMAT, C_SPARES, C_DEPOT, C_MISC];
ops_labels = {'Fuel/Oil/Lube', 'Direct Personnel', 'Indirect Personnel', ...
              'Consumables', 'Spares', 'Depot', 'Misc'};
ops_pcts = ops_costs/sum(ops_costs)*100;

ops_labels_display = cell(size(ops_labels));
for i = 1:length(ops_pcts)
    if ops_pcts(i) >= 3
        ops_labels_display{i} = sprintf('%s\n%.1f%%', ops_labels{i}, ops_pcts(i));
    else
        ops_labels_display{i} = '';
    end
end

p3 = pie(ops_costs, ops_labels_display);
for i = 1:2:length(p3)
    p3(i).FaceColor = colors_ops(ceil(i/2), :);
    p3(i).EdgeColor = 'white';
    p3(i).LineWidth = 1.5;
end
title(sprintf('Operating Cost: $%.1fM (%.0f yrs)', C_OPS/1e6, N_yr), 'FontSize', 12, 'FontWeight', 'bold');

% ----- Life Cycle Cost Pie Chart -----
subplot(2,2,4);
lcc_costs = [C_RDTE, C_ACQ, C_OPS, C_DISP];
lcc_labels = {'RDTE', 'Acquisition', 'Operations', 'Disposal'};
lcc_pcts = lcc_costs/sum(lcc_costs)*100;

lcc_labels_display = cell(size(lcc_labels));
for i = 1:length(lcc_pcts)
    lcc_labels_display{i} = sprintf('%s\n%.1f%%', lcc_labels{i}, lcc_pcts(i));
end

p4 = pie(lcc_costs, lcc_labels_display);
for i = 1:2:length(p4)
    p4(i).FaceColor = colors_lcc(ceil(i/2), :);
    p4(i).EdgeColor = 'white';
    p4(i).LineWidth = 1.5;
end
title(sprintf('Life Cycle Cost: $%.1fM', LCC/1e6), 'FontSize', 12, 'FontWeight', 'bold');

%% Figure 2: Detailed RDTE with Legend
figure('Position', [100, 100, 800, 600], 'Color', 'white');

% Create pie chart without labels
p_rdte = pie(rdte_costs);
for i = 1:2:length(p_rdte)
    p_rdte(i).FaceColor = colors_rdte(ceil(i/2), :);
    p_rdte(i).EdgeColor = 'white';
    p_rdte(i).LineWidth = 2;
end
% Remove text labels from pie
for i = 2:2:length(p_rdte)
    p_rdte(i).String = '';
end

% Create legend with values
legend_labels_rdte = cell(length(rdte_labels), 1);
for i = 1:length(rdte_labels)
    legend_labels_rdte{i} = sprintf('%s: $%.1fM (%.1f%%)', ...
        rdte_labels{i}, rdte_costs(i)/1e6, rdte_pcts(i));
end
legend(legend_labels_rdte, 'Location', 'eastoutside', 'FontSize', 10);
title(sprintf('RDTE Cost Breakdown\nTotal: $%.2fM', C_RDTE/1e6), ...
    'FontSize', 14, 'FontWeight', 'bold');

%% Figure 3: Detailed Production with Legend
figure('Position', [100, 100, 800, 600], 'Color', 'white');

p_prod = pie(prod_costs);
for i = 1:2:length(p_prod)
    p_prod(i).FaceColor = colors_prod(ceil(i/2), :);
    p_prod(i).EdgeColor = 'white';
    p_prod(i).LineWidth = 2;
end
for i = 2:2:length(p_prod)
    p_prod(i).String = '';
end

legend_labels_prod = cell(length(prod_labels), 1);
for i = 1:length(prod_labels)
    legend_labels_prod{i} = sprintf('%s: $%.1fM (%.1f%%)', ...
        prod_labels{i}, prod_costs(i)/1e6, prod_pcts(i));
end
legend(legend_labels_prod, 'Location', 'eastoutside', 'FontSize', 10);
title(sprintf('Production Cost Breakdown\nTotal: $%.2fM (%d Aircraft)', ...
    C_ACQ/1e6, N_m), 'FontSize', 14, 'FontWeight', 'bold');

%% Figure 4: Detailed Operating Cost with Legend
figure('Position', [100, 100, 800, 600], 'Color', 'white');

p_ops = pie(ops_costs);
for i = 1:2:length(p_ops)
    p_ops(i).FaceColor = colors_ops(ceil(i/2), :);
    p_ops(i).EdgeColor = 'white';
    p_ops(i).LineWidth = 2;
end
for i = 2:2:length(p_ops)
    p_ops(i).String = '';
end

legend_labels_ops = cell(length(ops_labels), 1);
for i = 1:length(ops_labels)
    legend_labels_ops{i} = sprintf('%s: $%.1fM (%.1f%%)', ...
        ops_labels{i}, ops_costs(i)/1e6, ops_pcts(i));
end
legend(legend_labels_ops, 'Location', 'eastoutside', 'FontSize', 10);
title(sprintf('Operating Cost Breakdown\nTotal: $%.2fM (%.0f Years)', ...
    C_OPS/1e6, N_yr), 'FontSize', 14, 'FontWeight', 'bold');

%% Figure 5: Detailed Life Cycle with Legend
figure('Position', [100, 100, 800, 600], 'Color', 'white');

p_lcc = pie(lcc_costs);
for i = 1:2:length(p_lcc)
    p_lcc(i).FaceColor = colors_lcc(ceil(i/2), :);
    p_lcc(i).EdgeColor = 'white';
    p_lcc(i).LineWidth = 2;
end
for i = 2:2:length(p_lcc)
    p_lcc(i).String = '';
end

legend_labels_lcc = cell(length(lcc_labels), 1);
for i = 1:length(lcc_labels)
    legend_labels_lcc{i} = sprintf('%s: $%.1fM (%.1f%%)', ...
        lcc_labels{i}, lcc_costs(i)/1e6, lcc_pcts(i));
end
legend(legend_labels_lcc, 'Location', 'eastoutside', 'FontSize', 10);
title(sprintf('Life Cycle Cost Breakdown\nTotal: $%.2fM', LCC/1e6), ...
    'FontSize', 14, 'FontWeight', 'bold');

%% Figure 6: Horizontal Bar Charts (Alternative Visualization)
figure('Position', [50, 50, 1400, 900], 'Color', 'white');
sgtitle('Cost Breakdown - Bar Chart View', 'FontSize', 16, 'FontWeight', 'bold');

% RDTE Bar
subplot(2,2,1);
barh(categorical(rdte_labels), rdte_costs/1e6, 'FaceColor', [0.2039 0.5412 0.7412]);
xlabel('Cost ($M)', 'FontWeight', 'bold');
title(sprintf('RDTE Cost: $%.1fM', C_RDTE/1e6), 'FontWeight', 'bold');
grid on;
set(gca, 'YDir', 'reverse');

% Production Bar
subplot(2,2,2);
barh(categorical(prod_labels), prod_costs/1e6, 'FaceColor', [0.8431 0.0980 0.1098]);
xlabel('Cost ($M)', 'FontWeight', 'bold');
title(sprintf('Acquisition Cost: $%.1fM', C_ACQ/1e6), 'FontWeight', 'bold');
grid on;
set(gca, 'YDir', 'reverse');

% Operating Bar
subplot(2,2,3);
barh(categorical(ops_labels), ops_costs/1e6, 'FaceColor', [0.1725 0.6275 0.1725]);
xlabel('Cost ($M)', 'FontWeight', 'bold');
title(sprintf('Operating Cost: $%.1fM', C_OPS/1e6), 'FontWeight', 'bold');
grid on;
set(gca, 'YDir', 'reverse');

% Life Cycle Bar
subplot(2,2,4);
barh(categorical(lcc_labels), lcc_costs/1e6, 'FaceColor', [1.0000 0.4980 0.0000]);
xlabel('Cost ($M)', 'FontWeight', 'bold');
title(sprintf('Life Cycle Cost: $%.1fM', LCC/1e6), 'FontWeight', 'bold');
grid on;
set(gca, 'YDir', 'reverse');

%% Final Summary Box
fprintf('\n');
fprintf('╔══════════════════════════════════════════════════════════════════════════════╗\n');
fprintf('║                          EXECUTIVE SUMMARY                                   ║\n');
fprintf('╠══════════════════════════════════════════════════════════════════════════════╣\n');
fprintf('║  Program Parameters:                                                         ║\n');
fprintf('║    • Production Run:     %d aircraft                                        ║\n', N_m);
fprintf('║    • Test Aircraft:      %d (including %d static)                             ║\n', N_rdte, N_st);
fprintf('║    • Service Life:       %.0f years (8,000 flight hours)                      ║\n', N_yr);
fprintf('║    • Annual Flight Hrs:  %d per aircraft                                     ║\n', U_ann_flt);
fprintf('╠══════════════════════════════════════════════════════════════════════════════╣\n');
fprintf('║  Cost Summary:                                                               ║\n');
fprintf('║    • RDTE Cost:          $%,.0fM                                        ║\n', C_RDTE/1e6);
fprintf('║    • Acquisition Cost:   $%,.0fM                                       ║\n', C_ACQ/1e6);
fprintf('║    • Operating Cost:     $%,.0fM                                       ║\n', C_OPS/1e6);
fprintf('║    • Life Cycle Cost:    $%,.0fM                                       ║\n', LCC/1e6);
fprintf('║    • Unit Price (AEP):   $%.2fM per aircraft                                ║\n', AEP/1e6);
fprintf('╚══════════════════════════════════════════════════════════════════════════════╝\n');

%% Other Functions
function C_avionics=avionics_cost_r(AEP)
% estimated avionics cost for military aircraft (Appendix C: page 367)
% suggested range is 5-40% of the airplane estimated price (Eq. 4.3)
    C_avionics=0.30*AEP;
end

function CER_year = CER(year)
% converts from 1970 dollars to dollars in whatever year you want
    CER_year=6.31752+0.104415*(year-2017); 
end