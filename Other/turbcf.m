% turbulent flow friction model based in fortran
% input Rex (Reynolds number based on component length)
%	Xme (Mach number)
%	TwTaw (Wall temperature ratio)
% output Cf

epsmax = 0.1e-8;
g = 1.4;
r = 0.88;
Te = 222;

xm = (g-1)*Xme(C)^2/2;
TawTe = 1 + r*xm;
F = TwTaw*TawTe;
Tw = F*Te;
A = sqrt(r*xm/F);
B = (1 + r*xm - F)/F;
denom = sqrt(4*A^2 + B^2);
Alpha = (2*A^2 - B)/denom;
Beta = B/denom;
Fc = ((1 + sqrt(F))/2)^2;

if (Xme(C) > 0.1)
  Fc = r*xm/((asin(Alpha) + asin(Beta))^2);
end

Xnum = (1 + 122*10^(-5/Tw)/Tw);
Denom = (1 + 122*10^(-5/Te)/Te);
Ftheta = sqrt(1/F)*(Xnum/Denom);
Fx = Ftheta/Fc;
RexBar = Fx*Rex(Comp);
Cfb = 0.074/(RexBar^0.2);

iter = 0;
eps = 1;

while (eps>epsmax)
 iter = iter + 1;
 if (iter>200)
  disp('Did not converge');
 end
 Cfo = Cfb;
 Xnum = 0.242 - sqrt(Cfb)*log10(RexBar*Cfb);
 Denom = 0.121 + sqrt(Cfb)/log(10);
 Cfb = Cfb*(1 + Xnum/Denom);
 eps = abs(Cfb-Cfo);
end

Cf = Cfb/Fc;