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
T04=1800; %Burner temp, K
Ma=3; %Flight Mach
QR=45E6; %Fuel Q_R, J/kg

%Flight conditions:
conditions.Ta=220; %flight static temperature, K
conditions.pa=18.75E3; %flight static pressure, Pa
conditions.R_air=287; %gas constant for air, J/kgK
conditions.gamma=1.4; %flight specific heat ratio

%Burner products:
conditions.R_products=conditions.R_air; %gas constant for combustion product, J/kgK

%Station efficiencies and specific heat ratios:
%Diffuser/inlet:
gammas.d=1.4;
rs.d=0.85;
%Burner:
gammas.b=1.35;
rs.b=0.99;
%Nozzle:
gammas.n=1.36;
rs.n=0.95;
%Flight stream:
gammas.a=conditions.gamma;


%call 'ramjet_func()' here:

%%

% put burner temperature array in K here
% put flight Mach number array here


%Meshgrid to get full condition space
[Ma,T04]=meshgrid(ma,t04);

%call 'ramjet_func()' for all elements in MA and T04 here:

%plot 2D contours here:
