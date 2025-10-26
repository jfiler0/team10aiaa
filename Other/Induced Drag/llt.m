function results = llt(b, c_r, c_t, alpha, alpha0, N)
% LLT with Fortran-style Oswald efficiency evaluation
% Computes cl distribution, lift, induced drag, and Oswald efficiency
%
% Inputs:
%   b      - wingspan
%   c_r    - root chord
%   c_t    - tip chord
%   alpha  - geometric angle of attack [rad]
%   alpha0 - zero-lift angle [rad]
%   N      - number of collocation points
%
% Output struct 'results' with fields:
%   CL, CDi, e        - Lift coefficient, induced drag coefficient, Oswald efficiency
%   AR, S             - Aspect ratio, wing area
%   a, gamma, alphai  - Fourier coeffs, circulation distribution, induced AoA distribution
%   y, c, cl          - Spanwise stations, chord distribution, sectional cl

    %% 1. Collocation points
    theta = (1:N)'/(N+1) * pi;  % column vector
    y     = cos(theta) * b/2;   % spanwise positions, column

    %% 2. Linear chord distribution
    c = c_t + (c_r - c_t) * (1 - 2*abs(y)/b);

    %% 3. LLT system for Fourier coefficients
    n = (1:N)'; 
    res = pi*c/(2*b) .* (alpha - alpha0) .* sin(theta); % RHS

    coef = zeros(N,N);
    for i=1:N
        for j=1:N
            coef(i,j) = sin(j*theta(i)) .* (j*c(i)/(4*b) + sin(theta(i)));
        end
    end

    a = coef \ res; % Fourier coefficients

    %% 4. Circulation and induced AoA
    gamma  = zeros(N,1);
    alphai = zeros(N,1);
    for i=1:N
        gamma(i)  = 2 * b * sum(a .* sin(n*theta(i)));
        alphai(i) = sum((n .* a) .* sin(n*theta(i))) / sin(theta(i));
    end

    %% 5. Wing area and aspect ratio
    yp = y(y>=0); cp = c(y>=0); [yp, idx] = sort(yp); cp = cp(idx);
    S = 2*trapz(yp, cp);
    AR = b^2 / S;

    %% 6. Local cl
    cl_local = 2*gamma ./ c;

    %% 7. Fortran-style Oswald efficiency from mirrored sine series
    e = fortran_oswald( flipud( y(y>0) ) , flipud( cl_local(y>=0) ), flipud( c(y>=0) ) );

    %% 8. Lift and induced drag coefficients
    CL  = pi * AR * a(1);        % CL from first Fourier mode
    CDi = CL^2 / (pi*AR*e);

    %% 9. Pack results
    results.CL     = CL;
    results.CDi    = CDi;
    results.e      = e;
    results.AR     = AR;
    results.S      = S;
    results.a      = a;
    results.gamma  = gamma;
    results.alphai = alphai;
    results.y      = y;
    results.c      = c;
    results.n      = n;
    results.cl     = cl_local;

    % Optional: export to LIDRAG format
    exportLIDRAG(results,"lidrage3.inp",30);
end

%% Helper function: compute Oswald efficiency
function e = fortran_oswald(y_half, cl_half, c_half)

% Compute Oswald efficiency using Fortran-style LIDRAG method
% Inputs:
%   y_half   - half-span positions (0 at root, b/2 at tip)
%   cl_half  - corresponding local lift coefficients
% Output:
%   e        - Oswald efficiency factor

    %% 1. Normalize half-span
    b2 = max(y_half);         % semi-span
    Y = y_half / b2;          % normalized: 0 → 1

    %% 2. Fine theta grid for sine series (as in LIDRAG)
    M = 4 * length(y_half);   % oversample for accuracy
    Y_fine = linspace(0, 1, M)';             % 0 → 1
    cl_fine = interp1(Y, cl_half, Y_fine, 'spline'); % interpolate
    c_fine = interp1(Y, c_half, Y_fine, 'spline'); % interpolate

    

    %% 3. Map to theta (0 → pi)
    % theta_fine = acos(1 - 2*Y_fine);  % ensures theta=0 at root, theta=pi at tip
    theta_fine = pi * Y_fine;  % simple linear mapping from 0→pi


    %% 4. Mirror to full sine series (odd extension)
    theta_full = [pi - flip(theta_fine); theta_fine];
    cl_full    = [flip(cl_fine); cl_fine];
    cl_full = cl_full / max(cl_full);
    c_full = [flip(c_fine); c_fine];


    % plot(theta_full, cl_full)

    %% 5. Compute Fourier sine coefficients B_n
    Npoints = length(theta_full);
    N = length(y_half);  % number of modes = original half-span points
    B = zeros(N,1);
    for n = 1:N
        % B(n) = (2 / Npoints) * sum(cl_full .* sin(n * theta_full));
        B(n) = (2/Npoints) * sum(cl_full .* c_full .* sin(n * theta_full));

    end

    %% 6. Compute Oswald efficiency
    A1 = B(1);
    n_vec = (1:N)';
    sum_term = sum(n_vec(2:end) .* (B(2:end).^2));
    e = A1^2 / sum_term; 
end


%% --- Export LIDRAG input file ---
function exportLIDRAG(results, filename, Nout)
b = max(results.y) - min(results.y);
y_half = results.y(results.y >= 0);
cl_half = results.cl(results.y >= 0);

% Interpolate to Nout points
y_nd = linspace(0,1,Nout);
Cl_out = interp1(y_half/(b/2), cl_half, y_nd, 'spline');

fid = fopen(filename,'w');
fprintf(fid, '%d.\n', Nout);
for i = 1:Nout
    fprintf(fid,' %.6f   %.6f\n', y_nd(i), Cl_out(i));
end
fclose(fid);

fprintf('Exported %d span stations to %s\n', Nout, filename);
end
