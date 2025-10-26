clear; clc; close all;

% Parameters
b = 8;
c_r = 1;
c_t = 0.5;
alpha = deg2rad(5);
alpha0 = deg2rad(0);
N = 20;

% --- Call the solver ---
res = llt(b, c_r, c_t, alpha, alpha0, N);

% --- Diagnostics after solver ---
a  = res.a;
n  = res.n;
AR = res.AR;
S  = res.S;

A1 = a(1);
sum_term = sum( n(2:end) .* (a(2:end).^2) );  % Fortran-style
e_calc = A1^2 / sum_term;                      
CL_calc = pi * A1 / 4;                         
CDi_calc = CL_calc^2 / (pi * AR * e_calc);

% Individual contributions for table/bar plot
contrib = n(2:end) .* (a(2:end).^2);

fprintf('\n--- Diagnostics ---\n');
fprintf('Area S = %.6f, AR = %.6f\n', S, AR);
fprintf('a1 = %.6e\n', A1);
fprintf('Sum-term S = %.6e\n', sum_term);
fprintf('e (from coeffs) = %.6f\n', e_calc);
fprintf('CL (from a1) = %.6f\n', CL_calc);
fprintf('CDi (from e) = %.6e\n', CDi_calc);

% Show first few coefficients and contributions
disp(table((1:min(12,N))', a(1:min(12,N)), ...
    [0; contrib(1:min(11,N-1))], ...
    'VariableNames', {'n','a_n','contrib'}));

% --- Plot coefficient decay and contributions ---
figure;
subplot(2,1,1);
semilogy(n, abs(a), '-o'); grid on;
xlabel('n'); ylabel('|a_n|'); title('Fourier coefficients a_n');

subplot(2,1,2);
bar(n(2:end), contrib);
xlabel('n'); ylabel('n * a_n^2'); title('Contribution to Fortran sum');

% --- Convergence test ---
Ns = [30 50 80 120 200];
e_vals = zeros(size(Ns));

for ii = 1:numel(Ns)
    res_test = llt(b, c_r, c_t, alpha, alpha0, Ns(ii));
    a_test = res_test.a;
    n_test = res_test.n;
    e_vals(ii) = a_test(1)^2 / sum(n_test(2:end) .* a_test(2:end).^2);
end

figure;
plot(Ns, e_vals, '-o'); grid on;
xlabel('N'); ylabel('e'); title('Convergence of Oswald efficiency');
