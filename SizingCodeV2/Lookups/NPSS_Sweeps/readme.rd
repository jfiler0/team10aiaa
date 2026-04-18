Currently the format of .mat files in this folder must obey the following:

When loaded have a struct with a variable ".DataTable"
This table then must have the following columns and names:
-TSFC [kg/N.s]
-Mach Number
-Altitude [ft]
-PLA (NPSS throttle where 0-100 is military, 100-150 is afterburner)
-Thrust [lb]
(Can have extra columns like "Point" but they aren't needed)