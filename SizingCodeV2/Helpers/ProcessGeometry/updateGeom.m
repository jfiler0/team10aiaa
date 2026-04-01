function geom = updateGeom(geom, settings)
    geom = updatePropulsionInfo(geom); 
        % Gets the needed propulsion parameters needed for the Prop model. May require further modification 
        % if a more advanced prop model is used. Currently references the engine lookup using an engine defenition in the geometry file
    geom = processGeometryDerived(geom); 
        % Primary update function which calculates derived variables and assigns them for the first time
        % Quite a bit of reduancy in this function which could be improved
    geom = processGeometryWeight(geom, settings); 
        % Use the simple Raymer model to predict WE and other required weight variables
    % geom = processGeometryConnections(geom);
        % Currently empty - placeholder for future improvement to speed up derived variable recalculation
    geom = generateGeometryOutline(geom);
        % Used for plots and AVL/idrag input. Surface sections and outlines
    geom.settings = settings; % i guess we can save this
end