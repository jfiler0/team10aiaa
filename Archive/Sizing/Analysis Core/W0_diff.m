% This function is quite critical to optimization stability

% This is a key constraint on the geometry

function diff = W0_diff(plane, missionList)
    % Run through all the missions and find the one with the highest required WTO
    W0_guess = plane.MTOW;
    W0_next = W0_guess / 10; % Start low and should be quickly replaced
    for i = 1:numel(missionList)
        [WTO_Next_i, ~, ~] = missionList(i).solveMission(plane, false);
        W0_next = max(W0_next, WTO_Next_i);
    end
    
    % This is less robust, and relies a bit more on a good starting guess. May need to fix the resiual in the future

    diff = W0_next - W0_guess; % You want this to be negative as it indicates the weight passed in is too high
end