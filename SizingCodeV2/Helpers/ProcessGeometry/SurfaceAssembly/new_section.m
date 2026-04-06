function sec = new_section(chord_length, le_x, le_y, opts)
    % Generates the derived variables needed for the section object
    arguments
        chord_length double % m

        % NOTE: These are inputted as essentially the local coordinates. (y is down the surface). Later it is converted back to body coords with z included
        le_x double % m -> relative to the aircraft nose
        le_y double % m -> relative to the centerline (XZ plane)

        opts.dihedral double = 0 % deg -> this stays relative to horizontal (XY plane)
        opts.twist double = 0 % deg -> applies to each section and does NOT stack. It is only applied for the .outline for an input to FORTRAN codes. It is not actually applied the x,y,z coords of the final sections. They stay untwisted
            % applied about the 1/4 chord
        opts.flap_length double = 0 % normalized by chord length. If 0 there is no flap
            % When integrated in a wing, the flap extends to the next section. If the section is the tip, any flaps are not consdered
        opts.tc double = 0.04 % thickness of the section
        opts.control_name string = ""
        opts.offset (1,3) double = [0 0 0] % needs to be three elements long. X, Y, Z. This offset stacks with each section. An initial offset applies to all sections after.

    end

    sec = struct();

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

    sec.offset = opts.offset; % this is just a vector which is added to the section when build in assemble_surface for more flexibility
end