function out = geom_vector_call(geom, model, fun_handle, structPath, num_vec)
    model.clear_mem

    out = zeros(size(num_vec));

    for i = 1:length(num_vec)
        geom = editGeom(geom, structPath, num_vec(i)); % does update internally
        model.geom = geom;

        out(i) = fun_handle(model.settings.codes.OVER_NO_READ_NO_WRITE);
    end
end