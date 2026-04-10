function mission = scale_mission_range(mission, scale)
    for i = 1:length(mission.data)
        if strcmp(mission.data(i).type.v, 'CRUISE')
            mission.data(i).distance.v = mission.data(i).distance.v * scale;
        end
    end
end