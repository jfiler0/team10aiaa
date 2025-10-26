function ac = aircraft_def()
    ac.Name = "ConceptA";
    ac.Span = 18.5;   % meters
    ac.WingArea = 45; % m^2
    ac.StabilityMargin = 0.08; % placeholder
    save('aircraft_data.mat','ac')
end
