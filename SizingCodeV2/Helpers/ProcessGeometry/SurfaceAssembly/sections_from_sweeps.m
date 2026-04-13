function sections = sections_from_sweeps(X_LE, Y_LE, root_chord, span_vec, le_sweep_vec, te_sweep_vec, opts)
    % X_LE, Y_LE, vector of section spans, vector of LE sweep, vector of TE sweep, OPTIONAL: vector of tc, vector of dihedral, offset parameter

    % Generates the derived variables needed for the section object
    arguments
        X_LE double % m
        Y_LE double % m
        root_chord double % m

        span_vec (1,:) double % m
        le_sweep_vec (1,:) double % deg (positive sweeps back)
        te_sweep_vec (1,:) double % deg (postiie sweeps back)

        % igonoring control surfaces
        opts.tc_vec (1,:) double = 0.04 * ones([1 length(span_vec)+1])
        opts.dihedral_vec (1,:) double = zeros([1 length(span_vec)+1])
        opts.offset (1,3) double = [0 0 0] % needs to be three elements long. X, Y, Z. This offset stacks with each section. An initial offset applies to all sections after.
    end

    if norm( [length(le_sweep_vec), length(te_sweep_vec), length(opts.tc_vec)-1, length(opts.dihedral_vec)-1] - length(span_vec) ) > 0
        error("One of the input vectors is not the correct length. span, le_sweep, te_sweep must match. tc and dihedral are the same but one longer than the other three.")
    end

    % first section
    sections = [new_section(root_chord, X_LE, Y_LE, tc=opts.tc_vec(1), dihedral=opts.dihedral_vec(1), offset=opts.offset)];

    for i=1:length(span_vec)
        X_LE = X_LE + span_vec(i) * tand(le_sweep_vec(i));
        Y_LE = Y_LE + span_vec(i);
        root_chord = root_chord - span_vec(i) * tand(le_sweep_vec(i)) + span_vec(i) * tand(te_sweep_vec(i));

        % note that offset should only apply to the first section
        sections = [sections, new_section(root_chord, X_LE, Y_LE, tc=opts.tc_vec(i+1), dihedral=opts.dihedral_vec(i+1))];
    end
end