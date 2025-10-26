% input file for friction program
% inputs all the data, or uses 
% available F-15 data

check = input('check with F-15 data? (1 for yes)');

if (check==1)
 SREF = 608;
 Scale = 1;
 N = 7;
 inmd=0;
 k = 1;
 swet(1) = 550;
 swet(2) = 75;
 swet(3) = 600;
 swet(4) = 305;
 swet(5) = 698;
 swet(6) = 222;
 swet(7) = 250;
 refl(1) = 54.65;
 refl(2) = 15;
 refl(3) = 35;
 refl(4) = 35.5;
 refl(5) = 12.7;
 refl(6) = 8.3;
 refl(7) = 6.7;
 TC(1) = 0.055;
 TC(2) = 0.12;
 TC(3) = 0.04;
 TC(4) = 0.117;
 TC(5) = 0.05;
 TC(6) = 0.05;
 TC(7) = 0.045;
 Icode(1) = 1;
 Icode(2) = 1;
 Icode(3) = 1;
 Icode(4) = 1;
 Icode(5) = 0;
 Icode(6) = 0;
 Icode(7) = 0;
 Ftrans(1) = 0;
 Ftrans(2) = 0;
 Ftrans(3) = 0;
 Ftrans(4) = 0;
 Ftrans(5) = 0;
 Ftrans(6) = 0;
 Ftrans(7) = 0;
 Xin(1) = 35;
 Xin(2) = 35;
 Xin(3) = 35;
 Mach(1) = 0.2;
 Mach(2) = 1.2;
 Mach(3) = 2;
 Trial = 3;

else

 SREF = input('Reference Area: ');
 Scale = input('Model Scale: ');
 N = input('Number of components: ');

 for (C = 1:N)
  disp(['----------------']);
  disp(['COMPONENT NUMBER ', num2str(C)]);
  disp(['----------------']);
  swet(C) = input('Wetted area: ');
  refl(C) = input('Reference length: ');
  TC(C) = input('Thickness ratio (or dia/length): ');
  Icode(C) = input('Planar (0) or Body of Revolution (1)? ');
  Ftrans(C) = input('Transitional flow (0:turb, 1:lam, ratio:lam/turb)? ');
 end

 Trial = input('Number of trials? ');
 inmd = input('Altitude(0) or Reynolds number/length(1)? ');
 if (inmd == 0)
  k = input('Metric (0) or Imperial (1)? ');
 end

 for (K = 1:Trial)
  disp(['------------ ']);
  disp(['TRAIL NUMBER ' num2str(K)]);
  disp(['------------ ']);
  if (inmd == 0)
   Xin(K) = input('Altitude (1000ft/km): ');
  else
   k = 1;
   Xin(K) = input('Reynolds number/length (Ren*10^6): ');
  end
  Mach(K) = input('Mach Number/Speed(mph): ');

 end

end
