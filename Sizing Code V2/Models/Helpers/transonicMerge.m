function out = transonicMerge(sub_fun, sup_fun, in)
    % sup_fun and sub_fun must both be a function of in
    transonic_range = [0.95 1.3];
    M_eps = 0.01;

    if(in.condition.mach <= transonic_range(1))
        out = sub_fun(in);
    elseif(in.condition.mach >= transonic_range(2))
        out = sup_fun(in);
    else
        M_vec = [transonic_range(1) transonic_range(1)-M_eps transonic_range(2) transonic_range(2)+M_eps];
        out_vec = zeros(size(M_vec));

        in_i = in;
        
        in_i.condition.mach = M_vec(1);
        out_vec(1) = sub_fun(in_i);
        in_i.condition.mach = M_vec(2);
        out_vec(2) = sub_fun(in_i);
        in_i.condition.mach = M_vec(3);
        out_vec(3) = sup_fun(in_i);
        in_i.condition.mach = M_vec(4);
        out_vec(4) = sup_fun(in_i);
        
        out = spline(M_vec, out_vec, in.condition.mach);
    end
end