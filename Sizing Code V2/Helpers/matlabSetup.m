function matlabSetup()
    % My master matlab setup script that gets plots looking nice
    
    clear;clc;close all;

    set(groot, 'DefaultFigureUnits', 'normalized');
    set(groot, 'DefaultFigurePosition', [0.1 0.1 0.8 0.8]);
    set(groot, 'DefaultFigureCreateFcn', @(fig, ~) set(fig, 'Position', [0.1 0.1 0.8 0.8], 'WindowStyle', 'docked'));

    % set(0, 'DefaultFigureWindowStyle', 'docked');
    
    set(groot, 'defaultAxesFontName', 'Times New Roman');
    set(groot, 'defaultTextFontName', 'Times New Roman');
    set(groot, 'defaultAxesFontSize', 16);
    set(groot, 'defaultTextFontSize', 12);
    set(groot, 'defaultLegendFontSize', 10);
    set(groot, 'defaultColorbarFontSize', 12);
    set(groot, 'defaultAxesTitleFontWeight', 'normal');
    
    % Set default interpreter to LaTeX
    set(groot, 'defaultTextInterpreter', 'latex');
    set(groot, 'defaultAxesTickLabelInterpreter', 'latex');
    set(groot, 'defaultLegendInterpreter', 'latex');

    % Line width
    set(groot, 'defaultLineLineWidth', 2);
end