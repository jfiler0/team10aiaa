% STARTUP FUNCTIONS
initialize
matlabSetup
build_kevin_cad

% INITIAL OBJECTS TO LOAD
build_default_settings
settings = readSettings();
geom = loadAircraft("kevin_cad", settings);

model = model_class(settings, geom);
perf = performance_class(model);

model.cond = levelFlightCondition(perf, 0, 0.3, 1); % Sea level, Mach 0.3, MTOW
clalphH = 2*pi;
CLalphH = clalphH/(1 + clalphH/(pi*model.geom.elevator.AR.v));
depsdalpha = 2*model.CLa/(pi*model.geom.wing.AR.v);
etaH  = 0.86; % Assume middle of the road 
l_h = model.geom.elevator.qrtr_chd_x.v - model.geom.wing.qrtr_chd_x.v;
xcg_ac_norm = linspace(-0.3,0.3,100);

eps0 = 2*model.cond.CL.v/(pi*model.geom.wing.AR.v);
CLH = CLalphH*-eps0;

zEng = 0.167386; %m

CMW = 0; % might need to change later?
CME = -model.cond.throttle.v*0.25*model.geom.prop.T0_NoAB.v*zEng/(model.cond.qinf.v*model.geom.wing.area.v*model.geom.wing.average_chord.v);

% Stability Requirement
SHSW_stability = model.CLa.*xcg_ac_norm./(CLalphH*etaH*(1-depsdalpha).*(l_h./model.geom.wing.average_chord.v -xcg_ac_norm));

% Control Requirement
SHSW_control = (model.cond.CL.v.*xcg_ac_norm./(CLH*etaH*l_h/model.geom.wing.average_chord.v)).*xcg_ac_norm + (CMW + CME)/(CLH*etaH*l_h/model.geom.wing.average_chord.v);

figure;

plot(SHSW_stability, xcg_ac_norm,'r');
hold on
plot(SHSW_control, xcg_ac_norm, 'g');
%xline(0,'k','LineWidth',4)
legend('Stability Limit','Control Limit');
xlabel('x_cg - x_ac normalized');
ylabel('SH/SW');

