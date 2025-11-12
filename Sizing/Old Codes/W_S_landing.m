function [W_S_landing] = W_S_landing(s_L, rho, g, mu, CL_max_landing, CD0, k_s_landing, beta)
% W_S Landing
%   Determines the wing loading of an aircraft during landing. 
W_S_landing = s_L*rho*g*(mu*CL_max_landing + 0.83*CD0) / (beta* k_s_landing^2);

end

