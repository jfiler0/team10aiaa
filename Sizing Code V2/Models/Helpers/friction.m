% main body for skin friction and form drag
% originally written in Fortran by W. Mason mason@aoe.vt.edu
% of the Department of Aerospace and Ocean engineering
% Virginia Tech, Blackburg, VA 24061
% modified several times in Fortran
% Translated to MATLAB by Paul Buller 1998
% modified form factors, Feb. 1, 2006

clear
clc
format short e;

% get input on aircraft geometry/flight conditions
finput;

% ratio of wall temperature/Adiabatic wall temperature
% wall temperature assumed to be at adiabatic wall temp
TwTaw = 1;

disp([' ']);

% start of Trial loop.  Each component is analysed under one 
% flight condition before moving on to the next flight condition

for (C=1:Trial)
disp(['Trial number ', num2str(C)]);

% if input is of form speed and altitude
if (inmd == 0)

 Z = Xin(C)*1000;
 stdatm;
 if (KK==1)
  disp('And for my next trick, I will go into orbit!!!');
  disp('Altitude too high, try again!!');
  break
 end

 % Mach data can be inputted as speed in mph
 % this converts it to Mach number
 if Mach(C) > 5
  Xme(C) = Mach(C)*1.466666/A;
 else
  Xme(C) = Mach(C);
 end

 RN(C) = RM*Xme(C);

 disp(['Mach number ', num2str(Xme(C))]);
 disp(['Altitude ', num2str(Z)]);
 disp(['Reynolds number/length ', num2str(RN(C))]);

% if input is of form speed and Reynolds number/length
else

 RN(C) = Xin(C)*10^6;

 % Mach data can be inputted as speed in mph
 % this converts it to Mach number
 if Mach(C) > 20
  Xme(C) = Mach(C)*1.466666/1116.45;
 else
  Xme(C) = Mach(C);
 end

 disp(['Mach number ', num2str(Xme(C))]);
 disp(['Reynolds number/length ', num2str(RN(C))]);

end


% start of the loop of component analysis under flight 
% conditions defined by stdatm, above

 for (Comp=1:N)

% set for factor based on T/C or d/l (decided by Icode)
%whm modified constants in Feb. 2006, 2.7 was 1.8, 100 was 50 - 
  if (Icode(Comp) == 0)
   FF = 1 + 2.7*TC(Comp) + 100*TC(Comp)^4;
  else
   FF = 1 + 1.5*TC(Comp)^1.5 + 7*TC(Comp)^3;
  end

  Rex(Comp) = RN(C)*refl(Comp);
% determine laminar drag coefficient
  lamcf;
  Cflam(Comp) = Cf;
% determine turbulent drag coefficient
  turbcf;
  Cfturb(Comp) = Cf;

% determine total drag, doesn't change if Ftrans = 0
  CFI(Comp) = Cfturb(Comp) - Ftrans(Comp)*(Cfturb(Comp) - Cflam(Comp));
  CFSW(Comp) = CFI(Comp)*swet(Comp);
  CFSWFF(Comp) = CFSW(Comp)*FF;
  CDCOMP(Comp) = CFSWFF(Comp)/SREF;

 end

 Sum1 = sum(CFSW);
 Sum2 = sum(CFSWFF);
 Sum3 = sum(CDCOMP);

% total form and friction drag for individual flight condition
 CD(C) = Sum1/SREF;
 CDFORM(C) = (Sum2-Sum1)/SREF;
 CDTOTAL(C) = CD(C) + CDFORM(C);

 disp(['Friction Drag ', num2str(CD(C))]);
 disp(['Form Drag ', num2str(CDFORM(C))]);
 disp(['Total Drag coefficient ', num2str(CDTOTAL(C))]);
 disp([' ']);

end

