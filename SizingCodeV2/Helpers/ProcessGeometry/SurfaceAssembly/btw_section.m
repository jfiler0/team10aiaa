function sec = btw_section(sec_inner, sec_outer, span_pos, opts)
    % sec_inner - the first section (try to keep as inboard)
    % sec_outer - the secodn section (try to keep as outboard)
    % span_pos - normalized (0-1) span position between the two.

    arguments
        sec_inner struct
        sec_outer struct
        span_pos double

        % If not defined these are derived as linear interp between the two surfaces
        opts.dihedral double = 0 % deg
        opts.twist double = 0 % deg'
        opts.tc double = 0.04
        
        % Flap only needs to be defined for inboard section
        opts.flap_length double = 0 % normalized by chord length. If 0 there is no flap
        opts.control_name string = ""
    end

    sec = sec_inner;

    sec.chord_length.v = sec_inner.chord_length.v * (1 - span_pos) + sec_inner.chord_length.v * span_pos;
    sec.le_x.v = sec_inner.le_x.v * (1 - span_pos) + sec_inner.le_x.v * span_pos;
    sec.le_y.v = sec_inner.le_y.v * (1 - span_pos) + sec_inner.le_y.v * span_pos;

    if isempty(opts.dihedral)
        sec.dihedral.v = sec_inner.dihedral.v * (1 - span_pos) + sec_inner.dihedral.v * span_pos;
    else
        sec.dihedral.v = opts.dihedral;
    end

    if isempty(opts.twist)
        sec.twist.v = sec_inner.twist.v * (1 - span_pos) + sec_inner.twist.v * span_pos;
    else
        sec.twist.v = opts.twist;
    end

    if isempty(opts.tc)
        sec.tc.v = sec_inner.tc.v * (1 - span_pos) + sec_inner.tc.v * span_pos;
    else
        sec.tc.v = opts.tc;
    end

    sec.flap_length.v = opts.flap_length;
    sec.control_name.v = opts.control_name;
end