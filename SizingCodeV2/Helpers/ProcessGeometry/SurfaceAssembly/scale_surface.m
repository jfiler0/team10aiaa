function surf = scale_surface(surf, scale, P)
    if nargin < 3
        P = [surf.qrtr_chd_x.v, surf.le_y.v, 0]; % estimate
    end
    % loop through each of the sections and rebuild with everything scaled by scale
    % scales around P (likely set to the 1/4 chord of the main wing

    sec = surf.sections(1);
    sections = scale_section(sec, scale, P);

    for i = 2:length(surf.sections)
        sec = surf.sections(i);
        sections(i) = scale_section(sec, scale, P);
    end
    surf = assemble_surface(sections);
end

function sec = scale_section(sec, scale, P)
    sec = new_section( ...
            sec.chord_length.v * scale, ...
            P(1) + scale*(sec.le_x.v - P(1)), ...
            P(2) + scale*(sec.le_y.v - P(2)), ...
            dihedral     = sec.dihedral.v, ...
            twist        = sec.twist.v, ...
            flap_length  = sec.flap_length.v, ...
            tc           = sec.tc.v, ...
            control_name = sec.control_name.v);
end