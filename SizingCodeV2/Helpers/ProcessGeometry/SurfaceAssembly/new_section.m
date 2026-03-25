function sec = new_section(chord_length, le_x, le_y, opts)
    % Generates the derived variables needed for the section object
    arguments
        chord_length double % m

        % NOTE: These are inputted as essentially the local coordinates. (y is down the surface). Later it is converted back to body coords with z included
        le_x double % m
        le_y double % m

        opts.dihedral double = 0 % deg
        opts.twist double = 0 % deg
        opts.flap_length double = 0 % normalized by chord length. If 0 there is no flap
        opts.tc double = 0.04
        opts.control_name string = ""
            % When integrated in a wing, the flap extends to the next section. If the section is the tip, any flaps are not consdered
    end

    sec = struct();

    % TODO: Fix wing dihedral positions

    sec.chord_length = json_entry("Length", chord_length, "m");
    sec.le_x = json_entry("Leading Edge X Position", le_x, "m");
    sec.le_yp = json_entry("Leading Edge YP Position", le_y, "m"); % P -> local coordinates
    sec.le_y = json_entry("Leading Edge Y Position", 0, "m");
    sec.le_z = json_entry("Leading Edge Z Position", 0, "m"); % this is overriden later

    sec.te_x = json_entry("Trailing Edge X Position", le_x + chord_length, "m");
    sec.te_yp = json_entry("Trailing Edge YP Position", le_y, "m"); % P -> local coordinates
    sec.te_y = json_entry("Trailing Edge Y Position", 0, "m");
    sec.te_z = json_entry("Trailing Edge Z Position", 0, "m"); % this is overriden later
    
    sec.dihedral = json_entry("Dihedral", opts.dihedral, "deg");
    sec.twist = json_entry("Twist", opts.twist, "deg");
    sec.flap_length = json_entry("Flap Length", opts.flap_length, "");
    sec.tc = json_entry("T/C - Thickness", opts.tc, "");
    sec.control_name = json_entry("Control Name", opts.control_name, "s");
end