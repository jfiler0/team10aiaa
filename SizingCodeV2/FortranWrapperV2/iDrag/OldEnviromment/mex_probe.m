%% mex_probe.m  — figure out exactly what idrag_mex expects
clear; clc;
addpath(fileparts(mfilename("fullpath")));
addpath(fullfile(fileparts(mfilename("fullpath")), "Applications"));

% Check it's found
disp(exist("idrag_mex","file"));  % should print 3

%% Test 1: wrong number of args — forces MEX to print its usage error
try
    idrag_mex();
catch ME
    disp("=== 0 args ==="); disp(ME.message);
end

%% Test 2: all scalars, bare minimum
try
    result = idrag_mex(...
        int32(0), ...   % input_mode
        int32(1), ...   % sym_flag
        0.5,     ...    % cl_design
        int32(0), ...   % cm_flag
        0.0,     ...    % cm_design
        0.25,    ...    % xcg
        0.25,    ...    % cp
        1.0,     ...    % sref
        1.0,     ...    % cavg
        int32(1), ...   % npanels
        zeros(1,4), ... % xc  (1x4)
        zeros(1,4), ... % yc
        zeros(1,4), ... % zc
        int32(30), ...  % nvortices  (scalar)
        int32(3),  ...  % spacing_flag (scalar)
        int32(1),  ...  % load_flag
        zeros(1,1) ...  % loads
    );
    fprintf("Test 2 (int32 scalars): CDi = %.8f\n", result);
catch ME
    disp("=== Test 2 failed ==="); disp(ME.message);
end

%% Test 3: same but int64
try
    result = idrag_mex(...
        int64(0), int64(1), 0.5, int64(0), 0.0, ...
        0.25, 0.25, 1.0, 1.0, int64(1), ...
        zeros(1,4), zeros(1,4), zeros(1,4), ...
        int64(30), int64(3), int64(1), zeros(1,1) ...
    );
    fprintf("Test 3 (int64): CDi = %.8f\n", result);
catch ME
    disp("=== Test 3 failed ==="); disp(ME.message);
end

%% Test 4: all double
try
    result = idrag_mex(...
        0, 1, 0.5, 0, 0.0, ...
        0.25, 0.25, 1.0, 1.0, 1, ...
        zeros(1,4), zeros(1,4), zeros(1,4), ...
        30, 3, 1, zeros(1,1) ...
    );
    fprintf("Test 4 (all double): CDi = %.8f\n", result);
catch ME
    disp("=== Test 4 failed ==="); disp(ME.message);
end

%% Test 5: nvortices/spacing as row vs column vectors
try
    result = idrag_mex(...
        int32(0), int32(1), 0.5, int32(0), 0.0, ...
        0.25, 0.25, 1.0, 1.0, int32(1), ...
        zeros(1,4), zeros(1,4), zeros(1,4), ...
        int32([30]), int32([3]), int32(1), zeros(1,1) ...  % explicit row vector
    );
    fprintf("Test 5 (int32 row vec): CDi = %.8f\n", result);
catch ME
    disp("=== Test 5 failed ==="); disp(ME.message);
end