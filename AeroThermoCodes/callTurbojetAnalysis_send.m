clear all
close all
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Set plot stuff:
set(0,'DefaultLineLineWidth',1.5)
% set(0,'DefaultLineColor',[1,1,1])
set(0,'DefaultLineMarkerSize',15)
set(0,'DefaultAxesFontSize',22)
set(0,'DefaultFigureColor',[1,1,1])
set(0,'DefaultTextFontSize',26)
set(0,'DefaultTextInterpreter','latex')
set(0,'DefaultTextFontName','Times-Roman')
set(0,'DefaultAxesFontName','Times-Roman')
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Design parameters:
T04=1700; %Burner temp, K
Ma=0; %Flight Mach
prc=10; %Compressor pressure ratio
QR=45E6; %Fuel Q_R, J/kg

%Flight conditions:
conditions.Ta=288.2; %flight static temperature, K
conditions.pa=101.30E3; %flight static pressure, Pa
conditions.R_air=287; %gas constant for air, J/kgK
conditions.gamma=1.4; %flight specific heat ratio

%Burner products:
conditions.R_products=conditions.R_air; %gas constant for combustion product, J/kgK

%Station efficiencies and specific heat ratios:
%Diffuser/inlet:
gammas.d=1.4;
etas.d=0.97;
%Compressor:
gammas.c=1.37;
etas.c=0.85;
%Burner:
gammas.b=1.35;
etas.b=1.0;
%Turbine:
gammas.t=1.33;
etas.t=0.90;
%Nozzle:
gammas.n=1.36;
etas.n=0.98;
%Flight stream:
gammas.a=conditions.gamma;

%call 'turbojet_func()' here:

%%

% put compressor pressure ratio array here

%call 'turbojet_func()' for all elements in PRC:

%plot performance curves:
