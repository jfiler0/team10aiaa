
function cost_struct = xanderscript_modified(geom, do_tables, do_figures)

    cost_struct = struct();

    %% Detailed Cost
    % Walks through Roskam Book VIII Chapters 3,4,6,7
    % For questions, ask Xander
    
    %% TODO:
    % avionics estimated to be 30% of AEP cost (Appendix C says 5-40)
    % Section 6: revisit depot costs bc we're on a carrier
    
    %% Aircraft-Dependent Inputs (pulled from geom JSON)
    W_TO = N2lb(geom.weights.mtow.v);            % lb

    % --- Empty weight ---
    % JSON doesn't carry weights.empty.v, so fall back to Raymer regression:
    %   W_e/W_TO = A * W_TO^C  ->  W_e = A * W_TO^(1+C), W_TO in lb
    if isfield(geom.weights,'empty') && isfield(geom.weights.empty,'v') ...
            && ~isempty(geom.weights.empty.v) && geom.weights.empty.v > 0
        W_ampr = N2lb(geom.weights.empty.v);
    else
        A_ray  = geom.weights.raymer.A.v;
        C_ray  = geom.weights.raymer.C.v;
        W_ampr = A_ray * W_TO^(1 + C_ray);        % lb (Raymer)
    end

    V_max = 563;                                  % knots (max level military, M0.85 @ SL)
    N_e   = geom.prop.num_engine.v;               % engines per aircraft

    % --- Engine unit cost ---
    % JSON doesn't carry prop.engine_cost_mil.v, so look up by engine name.
    % Values are approximate 2025 $M per engine, new-production.
    if isfield(geom.prop,'engine_cost_mil') && isfield(geom.prop.engine_cost_mil,'v') ...
            && ~isempty(geom.prop.engine_cost_mil.v) && geom.prop.engine_cost_mil.v > 0
        C_e_r = geom.prop.engine_cost_mil.v * 1e6;
    else
        engine_name = upper(strtrim(geom.prop.engine.v));
        switch engine_name
            case 'F100'
                C_e_r = 6.5e6;
            case 'F110'
                C_e_r = 7.5e6;   % GE F110-GE-129 class
            case 'F119'
                C_e_r = 15e6;
            case 'F135'
                C_e_r = 14e6;
            case 'F414'
                C_e_r = 4.86e6;
            otherwise
                warning('xanderscript_modified:UnknownEngine', ...
                    'Unknown engine "%s" - defaulting to $7.5M', engine_name);
                C_e_r = 7.5e6;
        end
    end

    C_p_r = 0;                                    % cost per propeller
    N_p   = 0;                                    % propellers per aircraft

    % TODO: This is not accurate
    W_F_used = 0.8*(W_TO - W_ampr);               % fuel used in lb per mission
    t_mis    = 3;                                 % hours per mission
    KLOC     = geom.input.kloc.v;
    
    %% Hardcoded Inputs
    N_m      = 500;   % number of aircraft produced during the production run
    N_rdte   = 8;     % static + flight test aircraft
    N_program = N_m + N_rdte;
    F_diff   = 1.5;   % advanced-tech factor (Augustine's law)
    F_cad    = 0.8;   % experienced CAD manufacturers
    R_e_r    = 76*CER(2025)/CER(1989);    % engineering hourly rate (secret program)
    N_st     = 2;                          % static test aircraft
    R_m_r    = 42*CER(2025)/CER(1989);    % mfg hourly rate (secret)
    F_mat    = 2;                          % material scale factor (2-2.5 composites)
    N_r_r    = 0.33;                       % RDTE production rate (units/month)
    N_r_m    = 500/10/12;                  % production rate (units/month)
    R_t_r    = 54*CER(2025)/CER(1989);    % tooling hourly rate (secret)
    F_obs    = 3;                          % stealth requirement factor
    
    %% Sec 3 RDTE
    
    % Sec 3.1 Airframe Engineering and Design Cost
    MHR_aed_r = 0.0396*W_ampr^0.791*V_max^1.526*N_rdte^0.183*F_diff*F_cad;
    cost_struct.RDTE.airframe_engineering = MHR_aed_r*R_e_r;
    
    % Sec 3.2 Dev Support and Testing Cost
    cost_struct.RDTE.development_support_testing = ...
        0.008325*W_ampr^0.873*V_max^1.890*N_rdte^0.346*CER(2025)*F_diff;
    
    % Sec 3.3 Flight Test Airplanes Cost
    C_avionics = 0.3/0.7*(51.813e6);   % TODO: update per iteration to get 30% of AEP
    cost_struct.RDTE.flight_test.engines_avionics = ...
        (C_e_r*N_e + C_p_r*N_p + C_avionics)*(N_rdte - N_st);
    MHR_man_r  = 28.984*W_ampr^0.74*V_max^0.543*N_rdte^0.524*F_diff;
    cost_struct.RDTE.flight_test.manufacturing_labor = MHR_man_r*R_m_r;
    cost_struct.RDTE.flight_test.materials = ...
        37.632*F_mat*W_ampr^0.689*V_max^0.624*N_rdte^0.792*CER(2025);
    MHR_tool_r = 4.0127*W_ampr^0.764*V_max^0.899*N_rdte^0.178*N_r_r^0.066*F_diff;
    cost_struct.RDTE.flight_test.tooling = MHR_tool_r * R_t_r;
    cost_struct.RDTE.flight_test.quality_control = 0.13*cost_struct.RDTE.flight_test.manufacturing_labor;
    C_fta_r = cost_struct.RDTE.flight_test.engines_avionics + ...
              cost_struct.RDTE.flight_test.manufacturing_labor + ...
              cost_struct.RDTE.flight_test.materials + ...
              cost_struct.RDTE.flight_test.tooling + ...
              cost_struct.RDTE.flight_test.quality_control;
    
    % Sec 3.4 Flight Test Operations Cost
    cost_struct.RDTE.flight_test_operations = ...
        0.001244*W_ampr^1.16*V_max^1.371*(N_rdte-N_st)^1.281*CER(2025)*F_diff*F_obs;
    
    % Sec 3.5 Test and Simulation Facilities Cost (applied at end)
    F_tsf = 0.1;
    
    % Sec 3.6 RDTE Profit (applied at end)
    F_pro_r = 0.08;
    
    % Sec 3.7 Financing RDTE Phase
    C_fin_r = 0;   % assumed 0 for military
    
    % Extra Sec: Software (from COCOMO)
    a = 3.6;
    b = 1.2;                               % fighters typically use embedded
    E = a*KLOC^b;                          % person-months
    cost_software = E*16000;               % $/person/month (COCOMO II, 2013)
    cost_struct.RDTE.software_development = cost_software*CER(2025)/CER(2013);
    
    % Final RDTE
    C_RDTE = (cost_struct.RDTE.airframe_engineering + ...
              cost_struct.RDTE.development_support_testing + ...
              C_fta_r + ...
              cost_struct.RDTE.flight_test_operations + ...
              C_fin_r + ...
              cost_struct.RDTE.software_development) / (1 - F_tsf - F_pro_r);
    cost_struct.RDTE.test_sim_facilitis = C_RDTE*F_tsf;
    cost_struct.RDTE.profit             = C_RDTE*F_pro_r;
    
    %% Sec 4 Manufacturing and Acquisition Cost
    N_acq = N_program;
    
    % 4.1 Airframe Engineering and Design Cost
    R_e_m = R_e_r;
    MHR_aed_program = 0.0396*W_ampr^0.791*V_max^1.526*N_program^0.183*F_diff*F_cad;
    cost_struct.production.airframe_engineering = ...
        MHR_aed_program*R_e_m - cost_struct.RDTE.airframe_engineering;
    
    % 4.2 Airplane Production Cost
    C_e_m        = C_e_r;             % same as RDTE (COTS)
    C_p_m        = 0;
    C_avionics_m = C_avionics;
    cost_struct.production.production.engines_avionics = ...
        (C_e_m*N_e + C_p_m*N_p + C_avionics_m)*N_m;
    C_int_m = 0;                       % interior cost (0 for military)
    R_m_m   = R_m_r;
    MHR_man_program = 28.984*W_ampr^0.74*V_max^0.543*N_program^0.524*F_diff;
    cost_struct.production.production.manufacturing_labor = ...
        MHR_man_program*R_m_m - cost_struct.RDTE.flight_test.manufacturing_labor;
    C_mat_program = 37.632*F_mat*W_ampr^0.689*V_max^0.624*N_program^0.792*CER(2025);
    cost_struct.production.production.materials = ...
        C_mat_program - cost_struct.RDTE.flight_test.materials;
    R_t_m = R_t_r;
    MHR_tool_program = 4.0127*W_ampr^0.764*V_max^0.899*N_program^0.178*N_r_m^0.066*F_diff;
    cost_struct.production.production.tooling = ...
        MHR_tool_program*R_t_m - cost_struct.RDTE.flight_test.tooling;
    cost_struct.production.production.quality_control = ...
        0.13*cost_struct.production.production.manufacturing_labor;
    C_apc_m = cost_struct.production.production.engines_avionics + C_int_m + ...
              cost_struct.production.production.manufacturing_labor + ...
              cost_struct.production.production.materials + ...
              cost_struct.production.production.tooling + ...
              cost_struct.production.production.quality_control;
    
    % 4.3 Production Flight Test Operations Cost
    F_ftoh   = 4;        % overhead factor
    t_pft    = 20;       % flight-test hours before delivery
    C_opshr  = 2.6556e4; % seeded from prior iteration; matches C_opshr2 at convergence
    cost_struct.production.flight_test_operations = N_m*C_opshr*t_pft*F_ftoh;
    
    % 4.4 Cost of financing manufacturing program
    C_fin_m = 0;   % 0 for military?
    
    C_MAN = cost_struct.production.airframe_engineering + C_apc_m + ...
            cost_struct.production.flight_test_operations + C_fin_m;
    
    % 4.5 Profit from Production
    F_pro_m = F_pro_r;
    cost_struct.production.profit = F_pro_m*C_MAN;
    
    C_ACQ = C_MAN + cost_struct.production.profit;
    AEP   = (C_ACQ + C_RDTE)/N_m;   % unit price per airplane
    
    %% Sec 6: Operating Cost of Military Airplanes
    
    % Sec 6.1 Program Fuel, Oil and Lubricants Cost
    F_OL   = 1.005;
    FP     = 6.30;                  % Jet-A price, 2025 $/gal (globalair.com)
    FD     = 0.81;                  % g/cm^3
    FD     = FD*8.345404;           % lb/gal
    U_ann_flt = 350;                % annual flight hours/aircraft (Table 6.1)
    N_mission = U_ann_flt/t_mis;
    N_res     = 0.1*N_acq;          % reserve aircraft
    N_yr      = 8000/U_ann_flt;     % 8000-hour lifetime
    L_R       = 2/100000;           % loss rate (F-18 Navy, Table 6.2)
    N_serv    = (N_acq - N_res)/(1 + 0.5*L_R*U_ann_flt*N_yr);
    N_loss    = L_R*N_serv*U_ann_flt*N_yr; %#ok<NASGU>
    cost_struct.operations.fuel_oil = F_OL*W_F_used*FP/FD*N_mission*N_serv*N_yr;
    
    % Sec 6.2 Direct Personnel Cost
    N_crew   = 1;
    R_cr     = 1.1;                 % crew ratio for fighter
    Pay_crew = (29286 + 12*400 + 11000)*CER(2025)/CER(1989);
    OHR_crew = 3;
    cost_struct.operations.personnel.crew = ...
        N_serv*N_crew*R_cr*Pay_crew*OHR_crew*N_yr;
    R_m_ml    = 45*CER(2025)/CER(1989);
    MHR_flthr = 20;                 % maintenance hr per flight hr (15-35 fighters)
    cost_struct.operations.personnel.maintenance = ...
        N_serv*N_yr*U_ann_flt*MHR_flthr*R_m_ml;
    C_PERSDIR = cost_struct.operations.personnel.crew + ...
                cost_struct.operations.personnel.maintenance;
    
    % Sec 6.3 Indirect Personnel Cost (applied at end)
    f_persind = 0.20;   % F-4 from Table 6.6
    
    % Sec 6.4 Consumable Materials
    R_conmat = 6.5*CER(2025)/CER(1989);
    cost_struct.operations.consumables = N_serv*N_yr*U_ann_flt*MHR_flthr*R_conmat;
    
    % Sec 6.5 Spares (applied at end)
    f_spares = 0.12;
    
    % Sec 6.6 Depots (applied at end)
    f_depot  = 0.10;
    
    % Sec 6.7 Misc
    cost_struct.operations.misc = 4*cost_struct.operations.consumables;
    
    C_OPS = (cost_struct.operations.fuel_oil + C_PERSDIR + ...
             cost_struct.operations.consumables + cost_struct.operations.misc) / ...
            (1 - f_persind - f_spares - f_depot);
    C_opshr2 = C_OPS/(N_serv*8000); %#ok<NASGU>
    cost_struct.operations.indirect_personnl = C_OPS*f_persind;
    cost_struct.operations.spares            = C_OPS*f_spares;
    cost_struct.operations.depot_maintenance = f_depot*C_OPS;
    
    %% Sec 7 Life Cycle Costs
    f_disp = 0.01;                  % disposal fraction
    LCC    = (C_RDTE + C_ACQ + C_OPS)/(1 - f_disp);
    cost_struct.disposal = LCC*f_disp;
    
    cost_struct.RDTE.total = cost_struct.RDTE.airframe_engineering + ...
        cost_struct.RDTE.development_support_testing + ...
        cost_struct.RDTE.flight_test.engines_avionics + ...
        cost_struct.RDTE.flight_test.manufacturing_labor + ...
        cost_struct.RDTE.flight_test.materials + ...
        cost_struct.RDTE.flight_test.tooling + ...
        cost_struct.RDTE.flight_test.quality_control + ...
        cost_struct.RDTE.flight_test_operations + ...
        cost_struct.RDTE.software_development + ...
        cost_struct.RDTE.test_sim_facilitis + ...
        cost_struct.RDTE.profit;
    
    cost_struct.production.total = cost_struct.production.airframe_engineering + ...
        cost_struct.production.production.engines_avionics + ...
        cost_struct.production.production.manufacturing_labor + ...
        cost_struct.production.production.materials + ...
        cost_struct.production.production.tooling + ...
        cost_struct.production.production.quality_control + ...
        cost_struct.production.flight_test_operations + ...
        cost_struct.production.profit;
    
    cost_struct.operations.total = cost_struct.operations.fuel_oil + ...
        cost_struct.operations.personnel.crew + ...
        cost_struct.operations.personnel.maintenance + ...
        cost_struct.operations.indirect_personnl + ...
        cost_struct.operations.consumables + ...
        cost_struct.operations.spares + ...
        cost_struct.operations.depot_maintenance + ...
        cost_struct.operations.misc;
    
    cost_struct.unit_cost = AEP;
    cost_struct.total     = cost_struct.RDTE.total + cost_struct.production.total + ...
                            cost_struct.operations.total + cost_struct.disposal;

    if do_tables
    
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
        fprintf('│ Airframe Engineering & Design                        │ %9.2f │ %7.2f%%  │\n', cost_struct.RDTE.airframe_engineering/1e6, cost_struct.RDTE.airframe_engineering/C_RDTE*100);
        fprintf('│ Development Support & Testing                        │ %9.2f │ %7.2f%%  │\n', cost_struct.RDTE.development_support_testing/1e6, cost_struct.RDTE.development_support_testing/C_RDTE*100);
        fprintf('│ Flight Test Airplanes                                │ %9.2f │ %7.2f%%  │\n', C_fta_r/1e6, C_fta_r/C_RDTE*100);
        fprintf('│   ├─ Engines & Avionics                              │ %9.2f │           │\n', cost_struct.RDTE.flight_test.engines_avionics/1e6);
        fprintf('│   ├─ Manufacturing Labor                             │ %9.2f │           │\n', cost_struct.RDTE.flight_test.manufacturing_labor/1e6);
        fprintf('│   ├─ Materials                                       │ %9.2f │           │\n', cost_struct.RDTE.flight_test.materials/1e6);
        fprintf('│   ├─ Tooling                                         │ %9.2f │           │\n', cost_struct.RDTE.flight_test.tooling/1e6);
        fprintf('│   └─ Quality Control                                 │ %9.2f │           │\n', cost_struct.RDTE.flight_test.quality_control/1e6);
        fprintf('│ Flight Test Operations                               │ %9.2f │ %7.2f%%  │\n', cost_struct.RDTE.flight_test_operations/1e6, cost_struct.RDTE.flight_test_operations/C_RDTE*100);
        fprintf('│ Software Development (COCOMO)                        │ %9.2f │ %7.2f%%  │\n', cost_struct.RDTE.software_development/1e6, cost_struct.RDTE.software_development/C_RDTE*100);
        fprintf('│ Test & Simulation Facilities (%.0f%%)                   │ %9.2f │ %7.2f%%  │\n', F_tsf*100, cost_struct.RDTE.test_sim_facilitis/1e6, cost_struct.RDTE.test_sim_facilitis/C_RDTE*100);
        fprintf('│ RDTE Profit (%.0f%%)                                     │ %9.2f │ %7.2f%%  │\n', F_pro_r*100, cost_struct.RDTE.profit/1e6, cost_struct.RDTE.profit/C_RDTE*100);
        fprintf('├──────────────────────────────────────────────────────┼───────────┼───────────┤\n');
        fprintf('│ TOTAL RDTE                                           │ %9.2f │   100.00%% │\n', C_RDTE/1e6);
        fprintf('└──────────────────────────────────────────────────────┴───────────┴───────────┘\n\n');
        
        % ----- Production/Acquisition Cost Table -----
        fprintf('┌──────────────────────────────────────────────────────────────────────────────┐\n');
        fprintf('│                    PRODUCTION/ACQUISITION COST BREAKDOWN                     │\n');
        fprintf('├──────────────────────────────────────────────────────┬───────────┬───────────┤\n');
        fprintf('│ Category                                             │  Cost ($M)│  Percent  │\n');
        fprintf('├──────────────────────────────────────────────────────┼───────────┼───────────┤\n');
        fprintf('│ Airframe Engineering & Design                        │ %9.2f │ %7.2f%%  │\n', cost_struct.production.airframe_engineering/1e6, cost_struct.production.airframe_engineering/C_ACQ*100);
        fprintf('│ Airplane Production Cost                             │ %9.2f │ %7.2f%%  │\n', C_apc_m/1e6, C_apc_m/C_ACQ*100);
        fprintf('│   ├─ Engines & Avionics                              │ %9.2f │           │\n', cost_struct.production.production.engines_avionics/1e6);
        fprintf('│   ├─ Manufacturing Labor                             │ %9.2f │           │\n', cost_struct.production.production.manufacturing_labor/1e6);
        fprintf('│   ├─ Materials                                       │ %9.2f │           │\n', cost_struct.production.production.materials/1e6);
        fprintf('│   ├─ Tooling                                         │ %9.2f │           │\n', cost_struct.production.production.tooling/1e6);
        fprintf('│   └─ Quality Control                                 │ %9.2f │           │\n', cost_struct.production.production.quality_control/1e6);
        fprintf('│ Production Flight Test Operations                    │ %9.2f │ %7.2f%%  │\n', cost_struct.production.flight_test_operations/1e6, cost_struct.production.flight_test_operations/C_ACQ*100);
        fprintf('│ Production Profit (%.0f%%)                               │ %9.2f │ %7.2f%%  │\n', F_pro_m*100, cost_struct.production.profit/1e6, cost_struct.production.profit/C_ACQ*100);
        fprintf('├──────────────────────────────────────────────────────┼───────────┼───────────┤\n');
        fprintf('│ TOTAL ACQUISITION                                    │ %9.2f │   100.00%% │\n', C_ACQ/1e6);
        fprintf('├──────────────────────────────────────────────────────┼───────────┼───────────┤\n');
        fprintf('│ Unit Price (AEP) for %d aircraft                    │ %9.2f │           │\n', N_m, AEP/1e6);
        fprintf('└──────────────────────────────────────────────────────┴───────────┴───────────┘\n\n');
        
        % ----- Operating Cost Table -----
        fprintf('┌──────────────────────────────────────────────────────────────────────────────┐\n');
        fprintf('│                        OPERATING COST BREAKDOWN                              │\n');
        fprintf('│                     (%.0f years, %d service aircraft)                         │\n', N_yr, round(N_serv));
        fprintf('├──────────────────────────────────────────────────────┬───────────┬───────────┤\n');
        fprintf('│ Category                                             │  Cost ($M)│  Percent  │\n');
        fprintf('├──────────────────────────────────────────────────────┼───────────┼───────────┤\n');
        fprintf('│ Fuel, Oil & Lubricants                               │ %9.2f │ %7.2f%%  │\n', cost_struct.operations.fuel_oil/1e6, cost_struct.operations.fuel_oil/C_OPS*100);
        fprintf('│ Direct Personnel                                     │ %9.2f │ %7.2f%%  │\n', C_PERSDIR/1e6, C_PERSDIR/C_OPS*100);
        fprintf('│   ├─ Crew Personnel                                  │ %9.2f │           │\n', cost_struct.operations.personnel.crew/1e6);
        fprintf('│   └─ Maintenance Personnel                           │ %9.2f │           │\n', cost_struct.operations.personnel.maintenance/1e6);
        fprintf('│ Indirect Personnel (%.0f%%)                             │ %9.2f │ %7.2f%%  │\n', f_persind*100, cost_struct.operations.indirect_personnl/1e6, cost_struct.operations.indirect_personnl/C_OPS*100);
        fprintf('│ Consumable Materials                                 │ %9.2f │ %7.2f%%  │\n', cost_struct.operations.consumables/1e6, cost_struct.operations.consumables/C_OPS*100);
        fprintf('│ Spares (%.0f%%)                                         │ %9.2f │ %7.2f%%  │\n', f_spares*100, cost_struct.operations.spares/1e6, cost_struct.operations.spares/C_OPS*100);
        fprintf('│ Depot Maintenance (%.0f%%)                              │ %9.2f │ %7.2f%%  │\n', f_depot*100, cost_struct.operations.depot_maintenance/1e6, cost_struct.operations.depot_maintenance/C_OPS*100);
        fprintf('│ Miscellaneous                                        │ %9.2f │ %7.2f%%  │\n', cost_struct.operations.misc/1e6, cost_struct.operations.misc/C_OPS*100);
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
        fprintf('│ RDTE                                                 │ %9.2f │ %7.2f%%  │\n', C_RDTE/1e6, C_RDTE/LCC*100);
        fprintf('│ Acquisition                                          │ %9.2f │ %7.2f%%  │\n', C_ACQ/1e6, C_ACQ/LCC*100);
        fprintf('│ Operations                                           │ %9.2f │ %7.2f%%  │\n', C_OPS/1e6, C_OPS/LCC*100);
        fprintf('│ Disposal (%.0f%%)                                        │ %9.2f │ %7.2f%%  │\n', f_disp*100, cost_struct.disposal/1e6, cost_struct.disposal/LCC*100);
        fprintf('├──────────────────────────────────────────────────────┼───────────┼───────────┤\n');
        fprintf('│ TOTAL LIFE CYCLE COST                                │ %9.2f │   100.00%% │\n', LCC/1e6);
        fprintf('└──────────────────────────────────────────────────────┴───────────┴───────────┘\n\n');
        
        %% Final Summary Box
        fprintf('\n');
        fprintf('╔══════════════════════════════════════════════════════════════════════════════╗\n');
        fprintf('║                          EXECUTIVE SUMMARY                                   ║\n');
        fprintf('╠══════════════════════════════════════════════════════════════════════════════╣\n');
        fprintf('║  Program Parameters:                                                         ║\n');
        fprintf('║    • Production Run:     %d aircraft                                        ║\n', N_m);
        fprintf('║    • Test Aircraft:      %d (including %d static)                              ║\n', N_rdte, N_st);
        fprintf('║    • Service Life:       %.0f years (8,000 flight hours)                       ║\n', N_yr);
        fprintf('║    • Annual Flight Hrs:  %d per aircraft                                    ║\n', U_ann_flt);
        fprintf('╠══════════════════════════════════════════════════════════════════════════════╣\n');
        fprintf('║  Cost Summary:                                                               ║\n');
        fprintf('║    • RDTE Cost:          $%9.2fM                                         ║\n', C_RDTE/1e6);
        fprintf('║    • Acquisition Cost:   $%9.2fM                                         ║\n', C_ACQ/1e6);
        fprintf('║    • Operating Cost:     $%9.2fM                                         ║\n', C_OPS/1e6);
        fprintf('║    • Life Cycle Cost:    $%9.2fM                                         ║\n', LCC/1e6);
        fprintf('║    • Unit Price (AEP):   $%.2fM per aircraft                                ║\n', AEP/1e6);
        fprintf('╚══════════════════════════════════════════════════════════════════════════════╝\n');
    
    end
    
    
    if do_figures
        %% =====================================================================
        %% CREATE IMPROVED PIE CHARTS
        %% =====================================================================
        
        colors_rdte = [
            0.2039 0.5412 0.7412;
            0.8431 0.0980 0.1098;
            0.1725 0.6275 0.1725;
            1.0000 0.4980 0.0000;
            0.5804 0.4039 0.7412;
            0.8902 0.4667 0.7608;
            0.4980 0.4980 0.4980;
        ];
        
        colors_prod = [
            0.2039 0.5412 0.7412;
            0.8431 0.0980 0.1098;
            0.1725 0.6275 0.1725;
            1.0000 0.4980 0.0000;
            0.5804 0.4039 0.7412;
            0.8902 0.4667 0.7608;
            0.9373 0.8941 0.0784;
            0.4980 0.4980 0.4980;
        ];
        
        colors_ops = [
            0.2039 0.5412 0.7412;
            0.8431 0.0980 0.1098;
            0.1725 0.6275 0.1725;
            1.0000 0.4980 0.0000;
            0.5804 0.4039 0.7412;
            0.8902 0.4667 0.7608;
            0.9373 0.8941 0.0784;
        ];
        
        colors_lcc = [
            0.2039 0.5412 0.7412;
            0.8431 0.0980 0.1098;
            0.1725 0.6275 0.1725;
            1.0000 0.4980 0.0000;
        ];
        
        %% Figure 1: Summary Dashboard (2x2 layout)
        figure('Position', [50, 50, 1400, 900]);
        sgtitle('Aircraft Program Cost Analysis Summary', 'FontSize', 16, 'FontWeight', 'bold');
        
        subplot(2,2,1);
        rdte_costs = [cost_struct.RDTE.airframe_engineering, cost_struct.RDTE.development_support_testing, C_fta_r, cost_struct.RDTE.flight_test_operations, cost_struct.RDTE.software_development, cost_struct.RDTE.test_sim_facilitis, cost_struct.RDTE.profit];
        rdte_labels = {'Airframe Eng', 'Dev Support', 'Flight Test A/C', ...
                       'Flight Test Ops', 'Software', 'Test Facilities', 'Profit'};
        rdte_pcts = rdte_costs/sum(rdte_costs)*100;
        rdte_labels_display = cell(size(rdte_labels));
        for i = 1:length(rdte_pcts)
            if rdte_pcts(i) >= 5
                rdte_labels_display{i} = sprintf('%s\n%.1f\\%%', rdte_labels{i}, rdte_pcts(i));
            else
                rdte_labels_display{i} = '';
            end
        end
        p1 = pie(rdte_costs, rdte_labels_display);
        colororder(colors_rdte);
        for i = 1:2:length(p1)
            p1(i).FaceColor = colors_rdte(ceil(i/2), :);
            p1(i).LineWidth = 1.5;
        end
        title(sprintf('RDTE Cost: \\$%.1fM', C_RDTE/1e6), 'FontSize', 12, 'FontWeight', 'bold');
        
        subplot(2,2,2);
        prod_costs = [cost_struct.production.airframe_engineering, cost_struct.production.production.engines_avionics, cost_struct.production.production.manufacturing_labor, cost_struct.production.production.materials, cost_struct.production.production.tooling, cost_struct.production.production.quality_control, cost_struct.production.flight_test_operations, cost_struct.production.profit];
        prod_labels = {'Airframe Eng', 'Engines/Avionics', 'Mfg Labor', 'Materials', ...
                       'Tooling', 'QC', 'Flight Test', 'Profit'};
        prod_pcts = prod_costs/sum(prod_costs)*100;
        prod_labels_display = cell(size(prod_labels));
        for i = 1:length(prod_pcts)
            if prod_pcts(i) >= 3
                prod_labels_display{i} = sprintf('%s\n%.1f\\%%', prod_labels{i}, prod_pcts(i));
            else
                prod_labels_display{i} = '';
            end
        end
        p2 = pie(prod_costs, prod_labels_display);
        for i = 1:2:length(p2)
            p2(i).FaceColor = colors_prod(ceil(i/2), :);
            p2(i).LineWidth = 1.5;
        end
        title(sprintf('Acquisition Cost: \\$%.1fM', C_ACQ/1e6), 'FontSize', 12, 'FontWeight', 'bold');
        
        subplot(2,2,3);
        ops_costs = [cost_struct.operations.fuel_oil, C_PERSDIR, cost_struct.operations.indirect_personnl, cost_struct.operations.consumables, cost_struct.operations.spares, cost_struct.operations.depot_maintenance, cost_struct.operations.misc];
        ops_labels = {'Fuel/Oil/Lube', 'Direct Personnel', 'Indirect Personnel', ...
                      'Consumables', 'Spares', 'Depot', 'Misc'};
        ops_pcts = ops_costs/sum(ops_costs)*100;
        ops_labels_display = cell(size(ops_labels));
        for i = 1:length(ops_pcts)
            if ops_pcts(i) >= 3
                ops_labels_display{i} = sprintf('%s\n%.1f\\%%', ops_labels{i}, ops_pcts(i));
            else
                ops_labels_display{i} = '';
            end
        end
        p3 = pie(ops_costs, ops_labels_display);
        for i = 1:2:length(p3)
            p3(i).FaceColor = colors_ops(ceil(i/2), :);
            p3(i).LineWidth = 1.5;
        end
        title(sprintf('Operating Cost: \\$%.1fM (%.0f yrs)', C_OPS/1e6, N_yr), 'FontSize', 12, 'FontWeight', 'bold');
        
        subplot(2,2,4);
        lcc_costs = [C_RDTE, C_ACQ, C_OPS, cost_struct.disposal];
        lcc_labels = {'RDTE', 'Acquisition', 'Operations', 'Disposal'};
        lcc_pcts = lcc_costs/sum(lcc_costs)*100;
        lcc_labels_display = cell(size(lcc_labels));
        for i = 1:length(lcc_pcts)
            lcc_labels_display{i} = sprintf('%s\n%.1f\\%%', lcc_labels{i}, lcc_pcts(i));
        end
        p4 = pie(lcc_costs, lcc_labels_display);
        for i = 1:2:length(p4)
            p4(i).FaceColor = colors_lcc(ceil(i/2), :);
            p4(i).LineWidth = 1.5;
        end
        title(sprintf('Life Cycle Cost: \\$%.1fM', LCC/1e6), 'FontSize', 12, 'FontWeight', 'bold');
        
        %% Figure 2: Detailed RDTE with Legend
        figure('Position', [100, 100, 800, 600]);
        p_rdte = pie(rdte_costs);
        for i = 1:2:length(p_rdte)
            p_rdte(i).FaceColor = colors_rdte(ceil(i/2), :);
            p_rdte(i).LineWidth = 2;
        end
        for i = 2:2:length(p_rdte)
            p_rdte(i).String = '';
        end
        legend_labels_rdte = cell(length(rdte_labels), 1);
        for i = 1:length(rdte_labels)
            legend_labels_rdte{i} = sprintf('%s: $%.1fM (%.1f\\%%)', ...
                rdte_labels{i}, rdte_costs(i)/1e6, rdte_pcts(i));
        end
        legend(legend_labels_rdte, 'Location', 'eastoutside', 'FontSize', 10);
        title(sprintf('RDTE Cost Breakdown\nTotal: \\$%.2fM', C_RDTE/1e6), ...
            'FontSize', 14, 'FontWeight', 'bold');
        
        %% Figure 3: Detailed Production with Legend
        figure('Position', [100, 100, 800, 600]);
        p_prod = pie(prod_costs);
        for i = 1:2:length(p_prod)
            p_prod(i).FaceColor = colors_prod(ceil(i/2), :);
            p_prod(i).LineWidth = 2;
        end
        for i = 2:2:length(p_prod)
            p_prod(i).String = '';
        end
        legend_labels_prod = cell(length(prod_labels), 1);
        for i = 1:length(prod_labels)
            legend_labels_prod{i} = sprintf('%s: \\$%.1fM (%.1f\\%%)', ...
                prod_labels{i}, prod_costs(i)/1e6, prod_pcts(i));
        end
        legend(legend_labels_prod, 'Location', 'eastoutside', 'FontSize', 10);
        title(sprintf('Production Cost Breakdown\nTotal: \\$%.2fM (%d Aircraft)', ...
            C_ACQ/1e6, N_m), 'FontSize', 14, 'FontWeight', 'bold');
        
        %% Figure 4: Detailed Operating Cost with Legend
        figure('Position', [100, 100, 800, 600]);
        p_ops = pie(ops_costs);
        for i = 1:2:length(p_ops)
            p_ops(i).FaceColor = colors_ops(ceil(i/2), :);
            p_ops(i).LineWidth = 2;
        end
        for i = 2:2:length(p_ops)
            p_ops(i).String = '';
        end
        legend_labels_ops = cell(length(ops_labels), 1);
        for i = 1:length(ops_labels)
            legend_labels_ops{i} = sprintf('%s: \\$%.1fM (%.1f\\%%)', ...
                ops_labels{i}, ops_costs(i)/1e6, ops_pcts(i));
        end
        legend(legend_labels_ops, 'Location', 'eastoutside', 'FontSize', 10);
        title(sprintf('Operating Cost Breakdown\nTotal: \\$%.2fM (%.0f Years)', ...
            C_OPS/1e6, N_yr), 'FontSize', 14, 'FontWeight', 'bold');
        
        %% Figure 5: Detailed Life Cycle with Legend
        figure('Position', [100, 100, 800, 600]);
        p_lcc = pie(lcc_costs);
        for i = 1:2:length(p_lcc)
            p_lcc(i).FaceColor = colors_lcc(ceil(i/2), :);
            p_lcc(i).LineWidth = 2;
        end
        for i = 2:2:length(p_lcc)
            p_lcc(i).String = '';
        end
        legend_labels_lcc = cell(length(lcc_labels), 1);
        for i = 1:length(lcc_labels)
            legend_labels_lcc{i} = sprintf('%s: \\$%.1fM (%.1f\\%%)', ...
                lcc_labels{i}, lcc_costs(i)/1e6, lcc_pcts(i));
        end
        legend(legend_labels_lcc, 'Location', 'eastoutside', 'FontSize', 10);
        title(sprintf('Life Cycle Cost Breakdown\nTotal: \\$%.2fM', LCC/1e6), ...
            'FontSize', 14, 'FontWeight', 'bold');
        
        %% Figure 6: Horizontal Bar Charts
        figure('Position', [50, 50, 1400, 900]);
        sgtitle('Cost Breakdown - Bar Chart View', 'FontSize', 16, 'FontWeight', 'bold');
        
        subplot(2,2,1);
        barh(categorical(rdte_labels), rdte_costs/1e6, 'FaceColor', [0.2039 0.5412 0.7412]);
        xlabel("Cost (\$M)", 'FontWeight', 'bold');
        title(sprintf('RDTE Cost: \\$%.1fM', C_RDTE/1e6), 'FontWeight', 'bold');
        grid on; set(gca, 'YDir', 'reverse');
        
        subplot(2,2,2);
        barh(categorical(prod_labels), prod_costs/1e6, 'FaceColor', [0.8431 0.0980 0.1098]);
        xlabel('Cost (\$M)', 'FontWeight', 'bold');
        title(sprintf('Acquisition Cost: \\$%.1fM', C_ACQ/1e6), 'FontWeight', 'bold');
        grid on; set(gca, 'YDir', 'reverse');
        
        subplot(2,2,3);
        barh(categorical(ops_labels), ops_costs/1e6, 'FaceColor', [0.1725 0.6275 0.1725]);
        xlabel('Cost (\$M)', 'FontWeight', 'bold');
        title(sprintf('Operating Cost: \\$%.1fM', C_OPS/1e6), 'FontWeight', 'bold');
        grid on; set(gca, 'YDir', 'reverse');
        
        subplot(2,2,4);
        barh(categorical(lcc_labels), lcc_costs/1e6, 'FaceColor', [1.0000 0.4980 0.0000]);
        xlabel('Cost (\$M)', 'FontWeight', 'bold');
        title(sprintf('Life Cycle Cost: \\$%.1fM', LCC/1e6), 'FontWeight', 'bold');
        grid on; set(gca, 'YDir', 'reverse');
    
    end

end

%% Other Functions
function C_avionics = avionics_cost_r(AEP) %#ok<DEFNU>
% Estimated avionics cost for military aircraft (Roskam VIII, App C).
% Suggested range is 5-40% of AEP (Eq. 4.3).
    C_avionics = 0.30*AEP;
end

function CER_year = CER(year)
% Cost Escalation Factor (Roskam VIII), rebased to 2017 dollars.
    CER_year = 6.31752 + 0.104415*(year - 2017);
end