function surf = assemble_surface(sections)
    if(length(sections)<2)
        error("Must have at least two sections to define a wing")
    end
    % Sections sorted by sections(:).le_y
    [~, idx] = sort(arrayfun(@(s) s.le_y.v, sections));
    sections = sections(idx);

    prev_y = 0;
    prev_yp = 0;
    prev_z = 0;
    for j = 1:length(sections)
        % loop through the sections to correct XYZ coordinates to the body using local dihedral
        sections(j).le_y.v = prev_y + (sections(j).le_yp.v - prev_yp) * cosd(sections(j).dihedral.v);
        sections(j).le_z.v = prev_z + (sections(j).le_yp.v - prev_yp) * sind(sections(j).dihedral.v);

        prev_y = sections(j).le_y.v;
        prev_yp = sections(j).le_yp.v;
        prev_z = sections(j).le_z.v;

        sections(j).te_y.v = prev_y;
        sections(j).te_z.v = prev_z;

        sections(j).le_coords = [sections(j).le_x.v, sections(j).le_y.v, sections(j).le_z.v];
        sections(j).te_coords = [sections(j).te_x.v, sections(j).te_y.v, sections(j).te_z.v];
    end

    surf = struct();
    surf.le_x = json_entry("Leading Edge X Position", sections(1).le_x.v, "m", true);
    surf.le_y = json_entry("Leading Edge Y Position", sections(1).le_y.v, "m", true);
    surf.root_chord = json_entry("Root Chord", sections(1).chord_length.v, "m", true);
    surf.tip_chord = json_entry("Tip Chord", sections(end).chord_length.v, "m", true);
    surf.span = json_entry("Span", sections(end).le_y.v * 2, "m", true);
    surf.taper_ratio = json_entry("Taper Ratio", surf.tip_chord.v / surf.root_chord.v, "m", true);

    surf.sections = sections;

    surf.area = json_entry("Surface Area", 0, "m2", true); % filled in a sec

    % Area weighted
    surf.average_chord = json_entry("Average Chord", 0, "m2", true); % filled in a sec
    surf.average_sweep = json_entry("Average Sweep", 0, "m2", true); % filled in a sec

    num_panels = length(sections)-1;
    for i = 1:num_panels
        area = 0.5 * (sections(i+1).le_y.v - sections(i).le_y.v)*( sections(i+1).chord_length.v + sections(i).chord_length.v );
        sweep = atan2d( sections(i+1).le_x.v - sections(i).le_x.v, sections(i+1).le_y.v - sections(i).le_y.v );

        surf.area.v = surf.area.v + area;
        surf.average_chord.v = surf.average_chord.v + 0.5 * ( sections(i+1).chord_length.v + sections(i).chord_length.v ) * area;
        surf.average_sweep.v = surf.average_sweep.v + sweep * area;
    end

    surf.average_chord.v = surf.average_chord.v / surf.area.v;
    surf.average_sweep.v = surf.average_sweep.v / surf.area.v;

    surf.AR = json_entry("Aspect Ratio", surf.span.v / surf.average_chord.v, "m", true);
end