function PROG_500_2025 = getcost(empty_weight, KLOC)
% Inputs:
% empty_weight - empty weight of the aircraft [lb]
% KLOC - thousands of lines of code
%
% Outputs:
% PROG_100_2025 - program cost of 100 aircraft in today's dollars
% 
% Notes:
% Yearly scaling performed with CPI, Consumer Price Index

AUW=empty_weight*0.62;
% aircraft unit weight is approx 62% of the empty weight according to Nicolai Chap 24.2

PROG_100_1977 = 550*AUW^(0.812);
% CER from RAND N2283-2 Table 25. Cost in thousands of 1977 dollars. AUW in
% lbs.

PROG_100_2025 = PROG_100_1977*1000*5.3461; % factor of 5.3461 for 1977-2025 CPI scaling
% [2025 dollars]

PROG_500_2025 = PROG_100_2025 + 0.7*PROG_100_2025 * (5^0.9) - 0.7*PROG_100_2025; 
% scales prouduction to 500 aircraft with a 90% learning curve.
% modern techniques make 80% learning curve no longer applicable
% we only want to be scaling the production run (approx 70% of program costs)

PROG_500_2025 = PROG_500_2025 +  0.3 * PROG_500_2025 * 0.4;
% scaling for materials because RAND assumes aluminum airframe. Materials
% assumed to be 30% of the program cost


% Software (from COCOMO):
% KLOC = thousands of lines of code
% For our aircraft: 20 million lines of code taken from the exponential rate of code increase
a=3.6;
b=1.2; % fighters typically use embedded systems

E = a*KLOC^b; % in person months
cost_software=E*16000; 
% 16,000 per person per month from COCOMO II (2013)
cost_software=cost_software*1.3907; % inflation

PROG_500_2025=PROG_500_2025+cost_software;
end