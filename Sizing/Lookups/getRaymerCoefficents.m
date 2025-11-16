function [A, C] = getRaymerCoefficents(type)

    weight_regression_lookup = readtable("weight_regression_lookup.xlsx");

    selectedType=weight_regression_lookup(ismember(weight_regression_lookup.Type, type),:); % get the table row asked for and return as a table

    if(isempty(selectedType))
        error("Did not find regression for aircrft type: " + type)
    end

    A = selectedType.A;
    C = selectedType.C;

end