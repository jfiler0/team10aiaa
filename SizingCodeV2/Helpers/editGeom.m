function geom = editGeom(geom, structPath, value, do_update)

    structChain = strsplit(structPath, '.');

    if(readNestedField(geom, structChain, 'd') == 1)
        error("Editing geom path: '%s' is not valid as it is a derived variable.", structPath)
    end

    geom = assignNestedField(geom, structChain, value);

    if(nargin < 4)
        do_update = true;
    end

    if(do_update)
        geom = updateGeom(geom);
    end
end