function matlabSetup()
    
    clear;clc;close all;
    set(0,'defaultfigureposition',[50 80 1800 950]')
    
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