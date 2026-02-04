clear; 
clc;
% Parameters
footprint_range = [4,20,40,80];
time_range = [5, 10, 15, 20];    
[R_mesh, T_mesh] = meshgrid(footprint_range/2, time_range);
area_data = ((24*3600) ./ (T_mesh * 60)) .* (R_mesh.^2 * pi);

ticks_area = (linspace(0, 1, 6).^2) *max(area_data,[],"all");

Faktor_Radius = R_mesh(:);
Faktor_Zeit = T_mesh(:);
Antwort_Flaeche = area_data(:);

% Visualisation
figure;
h = interactionplot(Antwort_Flaeche, {Faktor_Radius, Faktor_Zeit}, ...
    'Varnames', {'Radius (km)', 'Service Time (min)'});

allAxes = findobj(gcf, 'Type', 'axes');
for i = 1:length(allAxes)
    ax = allAxes(i);
    ax.YAxis.TickValues = ticks_area;
    ax.YAxis.Exponent = 0;    
    ax.YAxis.TickLabelFormat = '%.0f';
    ax.YAxis.TickLabelRotation = 0; 
    ylabel(ax, ''); 
    
end



annotation('textarrow', [0.03 0.03], [0.5 0.5], 'string', 'Service Area (km^2)', ...
    'HeadStyle', 'none', 'LineStyle', 'none', 'TextRotation', 90, ...
    'FontSize', 12, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
set(gcf, 'Units', 'normalized');
set(allAxes, 'Units', 'normalized');
grid on 