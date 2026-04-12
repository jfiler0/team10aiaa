settings = readSettings();

writeStoreStruct("AIM-7", "AIM-7 Sparrow", lb2N(510), 3.7, 0.2, settings.codes.MISSILE );
writeStoreStruct("AIM-9X", "AIM-9x Sidewinder", lb2N(188), 3.02, 0.127, settings.codes.MISSILE );
writeStoreStruct("AIM-120", "AIM-120 AMRAAM", lb2N(356), 3.65, 0.178, settings.codes.MISSILE );
writeStoreStruct("AGM-88", "AGM-88 HARM", lb2N(796), 4.17, 0.254, settings.codes.MISSILE );


% 480 gal tank -> 1.817 m3 -> ~820kg/m3 (jeta)

writeStoreStruct("FPU-12", "FPU-12 Drop Tank", lb2N(360), ft2m(15), in2m(32), settings.codes.TANK, gal2L(480));
writeStoreStruct("300GAL", "F16 300gal Drop Tank", lb2N(360*300/480), ft2m(14.4), ft2m(2.74), settings.codes.TANK, gal2L(300)); 
writeStoreStruct("370GAL", "F16 370gal Drop Tank", lb2N(360*370/480), ft2m(16.94), ft2m(2.24), settings.codes.TANK, gal2L(370));
% f16 tank dimenions from: https://github.com/NikolaiVChr/f16/issues/346


writeStoreStruct("Mk-83", "Mk-83 JDAM", lb2N(985), 3, 0.35, settings.codes.BOMB);
writeStoreStruct("Mk-84", "Mk-84 JDAM", lb2N(985), 3.83, 0.46, settings.codes.BOMB);
writeStoreStruct("AAQ-28", "AN/AAQ-28 Litening", lb2N(459), 2.2, 0.406, settings.codes.POD);

writeStoreStruct("X", "Empty", 0, 0, 0, settings.codes.POD);
