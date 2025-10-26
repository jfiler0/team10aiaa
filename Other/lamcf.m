% lamcf from the internet program originally in Fortran
% input Rex (reynolds number based on part length)
%	Xme (Mach number)
%	TwTaw (ratio of wall temperature)
% output Cf
 
g = 1.4;
Pr = 0.72;
R = sqrt(Pr);
TE = 390;
TK = 200;

TwTe = TwTaw*(1 + R*(g - 1)*Xme(C)^2/2);
TstTe = 0.5 + 0.039*Xme(C)^2 + 0.5*TwTe;

cstar = sqrt(TstTe)*(1 + TK/TE)/(TstTe + TK/TE);

Cf = 2*0.664*sqrt(cstar)/sqrt(Rex(Comp));