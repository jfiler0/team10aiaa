function out = geom_vector_call(geom, model, fun_name, structPath, num_vec)

% out = geom_vector_call(@model.CD0

    model.clear_mem

    structChain = strsplit(structPath, '.');

    out = zeros(size(num_vec));

    for i = 1:length(num_vec)
        geom = assignNestedField( geom, structChain, num_vec(i) );
        model.geom = geom;

        geom = processGeometryDerived(geom); 
        geom = processGeometryWeight(geom);

        out(i) = model.(fun_name)(model.settings.codes.OVER_NO_READ_NO_WRITE);
    end
end