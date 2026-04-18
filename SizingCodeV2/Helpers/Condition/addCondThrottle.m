function cond = addCondThrottle(cond, throttle)
    % This is seperated out as generateCondition and levelFlightCondition both need it
    
    if(max(throttle) > 1)
        error("Throttle cannot be above 1.")
    end
    cond.throttle.v = throttle;
    cond.mil_throttle.v = min(throttle, 0.9)/0.9; % Goes from 0-1 from output between throttle=0-0.9
    cond.ab_throttle.v = (max(throttle, 0.9) - 0.9)/0.1; % Stays 0 unitl throttle = 0.9 and grows to 1between 0.9-1
end