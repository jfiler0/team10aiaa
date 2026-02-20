function geom = loadAircraft(name)
    geom = readAircraftFile(name); 
    geom = updateGeom(geom);
end