function  kgNs = lbmlbfhr_2_kgNs(lbmlbfhr)
% For TSFC conversion, lbm/lbf*hr to kg/N*s
    kgNs = lbmlbfhr/(2.2046 * 3600 / 0.22481);
    % 2.2046 lbm/kg, 3600 s/hr, 0.22481 lbf/N
end