% MAIN WING DEFENITION - only the inboard side of the flap must be defined
    sec0 = new_section(8, 8, 1, tc=0.06);
    sec1 = new_section(5.07, 8+8-5.07, 2, tc=0.04);
    sec6 = new_section(1.686, 8+8-1.686, 7, tc=0.02);
    
    % MAIN FLAP
    sec2 = btw_section(sec1, sec6, 0.1, flap_length=0.2, control_name="Main Flap");
    sec3 = btw_section(sec1, sec6, 0.5);
    
    % AILERON
    sec4 = btw_section(sec1, sec6, 0.6, flap_length=0.1, control_name="Aileron");
    sec5 = btw_section(sec1, sec6, 0.9);
    
    main_wing = assemble_surface([sec0, sec1, sec2, sec3, sec4, sec5, sec6]);
    main_wing.average_chord
