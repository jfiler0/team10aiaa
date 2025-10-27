 function performance=ramjet_func(conditions,gammas,rs,Ma,T04,QR)
%MATLAB function to compute performance of ramjet engines,
%following the analysis of Hill and Peterson.
%Inputs:
%-conditions: Structure for flight conditions
%conditions.Ma - flight Mach number
%conditions.Ta - flight static temperature (K)
%conditions.pa - flight static pressure (Pa)
%conditions.R_air - gas constant for air (J/kgK)
%conditions.R_products - gas constant for combustion products
%
%-gammas: structure for specific heat ratios throughout the engine
%gammas.a - flight gamma
%gammas.d - diffuser
%gammas.b - burner
%gammas.n - nozzle


%-rs: structure for component pressure ratios, as gammas structure

%T04: burner outlet tempearture (K)
%QR: fuel heating value in J/kg
%To follow, all units are base SI

%Outputs
%-performance: Structure for performance
%performance.ST - specific thrust (N/(kg/s))
%performance.TSFC - thrust specific fuel consumption (kg/s)/N
%performance.etaP - propulsion efficiency
%performance.etaT - thermal efficiency
%performance.eta0 - overall efficiency

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%To follow, all units are base SI

%Flight conditions:
Ta=conditions.Ta;
pa=conditions.pa;
gamma_a=gammas.a;
R_air=conditions.R_air;
R_products=conditions.R_products;

ua=Ma*sqrt(gamma_a*R_air*Ta);


%Engine parameters:
%Core:
gamma_d=gammas.d;
rd=rs.d;
gamma_b=gammas.b;
rb=rs.b;

% QR=45E6;

%nozzle:
gamma_n=gammas.n;
rn=rs.n;

%%Turbojet:

%2. Diffuser outlet:
T02=Ta*(1+(gamma_a-1)/2*Ma.^2);
p02=rd*pa*(1+(gamma_a-1)/2*Ma.^2).^(gamma_a/(gamma_a-1));

%3. Burner inlet:
p03=p02;
T03=T02;
cp_burner=R_air*gamma_b/(gamma_b-1);

%4. Burner outlet:
T04_ratio=T04./T03;
f=(T04_ratio-1)./(QR./(cp_burner*T03)-T04_ratio);
p04=rb*p03;


%5. Burner outlet duct
T05=T04;
p05=p04;


%6. Nozzle inlet:
T06=T05;
p06=p05;

%7. Nozzle exit:
p0e=p06*rn;
Me=sqrt(2/(gamma_n-1).*((p0e/pa).^((gamma_n-1)/gamma_n)-1)); %Assumes pe=pa!
Te=T06.*(1+(gamma_n-1)/2*Me.^2).^(-1);
ue=Me.*sqrt(gamma_n*R_products*Te);

performance.ST=(1+f).*ue-ua;
performance.TSFC=f./performance.ST;
performance.etaP=performance.ST.*ua./((1+f).*ue.^2/2-(1)*ua.^2/2);
performance.etaT=((1+f).*ue.^2/2-(1)*ua.^2/2)./(f*QR);
performance.eta0=performance.etaP.*performance.etaT;

