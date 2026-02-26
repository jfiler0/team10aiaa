function strut = missionSeg(name, type, input, vel_cons, M_cons, h_cons)
    % type = an array of characters that defines how mission_calculator will interpret the section
    %   'CRUISE' -> objective is to minimize specific fuel consumption (also works as climb seg)
    %   'LOITER' -> objective is to minimize mdotf
    %   'COMBAT' -> objective is to maximize sustained turn rate
    %   'FIXED_WF' -> just applies a fixed scaling to the current fuel weights (landing/takeoff)

    % input = can be a scaler or an array depending on the section
    %   CRUISE : [range in meters]
    %   LOITER : [time in minutes]
    %   COMBAT : [time in minutes, load factor, list of store indices to deploy during section]
    %   FIXED_WF : [the WF to apply]

    % vel_cons / M_cons
    %   These two cannot conflict or there will be an error
    %   There are three configurations
    %       [START, NaN] -> the constraint applys as a constant the entire time
    %       [NaN, END] -> unconstraint at the start and begins weighting as S^2 (more to the end).
    %       [START, END] -> linear interp between the two constraints

    strut = struct();

    % SAVE THE INPUTS
    strut.name = json_entry("Name", name, "s");
    strut.type = json_entry("Name", type, "s");
    strut.input = input;
    strut.vel_cons = vel_cons;
    strut.M_cons = M_cons;
    strut.h_cons = h_cons;

    switch type
        case 'CRUISE'
            strut.distance = json_entry("Distance", input(1), "m"); % meters
        case 'LOITER'
            strut.time = json_entry("Time", input(1), "min"); % minutes
        case 'COMBAT'
            strut.time = json_entry("Time", input(1), "min"); % minutes
            strut.load_factor = json_entry("Load Factor", input(2), "");
            strut.racks_to_deploy = input(3:end);
            if isempty(strut.racks_to_deploy)
                strut.do_deploy = false;
            else
                strut.do_deploy = true;
            end
        case 'FIXED_WF'
            strut.WFi = json_entry("WF Applied", input(1), "");
        otherwise
           error("'%s' is not a recognized mission segment type.", type);
    end
end