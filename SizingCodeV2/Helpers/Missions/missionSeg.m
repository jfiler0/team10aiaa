function strut = missionSeg(name, type, input, vel_cons, h_cons)
    % type = an array of characters that defines how mission_calculator will interpret the section
    %   'CRUISE' -> objective is to minimize specific fuel consumption (also works as climb seg)
    %   'LOITER' -> objective is to minimize mdotf
    %   'COMBAT' -> objective is to maximize sustained turn rate
    %   'FIXED_WF' -> just applies a fixed scaling to the current fuel weights (landing/takeoff)

    % input = can be a scaler or an array depending on the section
    %   CRUISE : [range in meters]
    %   LOITER : [time in minutes]
    %   COMBAT : [time in minutes, load factor, list of store indices to deploy during section]
    %   FIXED_WF : [the WF to apply, time in minutes]

    % vel_cons
    %   There are three configurations
    %       [START, NaN] -> the constraint applys as a constant the entire time
    %       [NaN, END] -> unconstraint at the start and begins weighting as S^2 (more to the end).
    %       [START, END] -> linear interp between the two constraints

    if nargin < 4
        vel_cons = [NaN, NaN];
    end
    if nargin < 5
        h_cons = [NaN, NaN];
    end

    strut = struct();

    % SAVE THE INPUTS
    strut.name = json_entry("Name", name, "s");
    strut.type = json_entry("Name", type, "s");
    strut.input = input;

    strut.vel_start = vel_cons(1);
    strut.vel_end = vel_cons(2);

    strut.h_start = h_cons(1);
    strut.h_end = h_cons(2);

    switch type
        case 'CRUISE'
            strut.distance = json_entry("Distance", input(1), "m"); % meters

            strut.time = NaN; strut.load_factor = NaN; strut.racks_to_deploy = NaN; strut.WFi = NaN;
        case 'LOITER'
            strut.time = json_entry("Time", input(1), "min"); % minutes

            strut.distance = NaN; strut.load_factor = NaN; strut.racks_to_deploy = NaN; strut.WFi = NaN;
        case 'COMBAT'
            strut.time = json_entry("Time", input(1), "min"); % minutes
            strut.load_factor = json_entry("Load Factor", input(2), "");
            strut.racks_to_deploy = input(3:end);
            if isempty(strut.racks_to_deploy)
                strut.do_deploy = false;
            else
                strut.do_deploy = true;
            end

            strut.distance = NaN; strut.WFi = NaN;
        case 'FIXED_WF'
            strut.WFi = json_entry("WF Applied", input(1), "");
            strut.time = json_entry("Time", input(1), "min"); % minutes

            strut.distance = NaN; strut.load_factor = NaN; strut.racks_to_deploy = NaN;
        otherwise
           error("'%s' is not a recognized mission segment type.", type);
    end
end