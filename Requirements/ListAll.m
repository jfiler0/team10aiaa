% List all components and parameters in your architecture
model = systemcomposer.openModel("AircraftArch");
arch = model.Architecture;

function listAll(arch, prefix)
    for i = 1:numel(arch.Components)
        c = arch.Components(i);
        fullPath = prefix + "/" + c.Name;
        fprintf('\nCOMPONENT: %s\n', fullPath);
        params = c.Parameters;
        for j = 1:numel(params)
            fprintf('  param: %s = %s\n', params(j).Name, params(j).Value);
        end
        if numel(c.Architecture.Components) > 0
            listAll(c.Architecture, fullPath);
        end
    end
end

listAll(arch, "AircraftArch");