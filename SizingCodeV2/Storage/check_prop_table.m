sidd_file = load("C:\Users\jfile\Downloads\TSFC_DataTable_ThrottleSweep.mat");

table = sidd_file.DataTable;
disp(table)
max(table.Thrust)

unique(table.("Mach Number"))
unique(table.("Altitude"))
unique(table.("PLA"))