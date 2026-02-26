function geom = loadAircraft(name, settings)
    geom = readAircraftFile(name); 
    geom = updateGeom(geom, settings);
end