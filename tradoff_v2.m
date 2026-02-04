clear; clc;
%% 1. Parameter Definitions
f = 2.1e9; 
c = 299792458; 
lambda = c/f; h_geo = 35786000;
N_list = 5:20:90;          
D_list = 1:2:10;             
Gap_list = 50:100:500;      
k_val = 2*pi/lambda; 
u_side = sin(deg2rad(linspace(0, 90, 2000))); 

% --- FIXED: Pre-allocate for 5 columns instead of 4 ---
total_rows = length(N_list)*length(D_list)*length(Gap_list);
results = zeros(total_rows, 5); 
res_idx = 1;

%% 2. Simulation Loop
for N = N_list
    p_x_base = zeros(N, 1);
    p_y_base = zeros(N, 1);
    span = sqrt(N) * 1.5;
    
    for i = 1:N
        valid = false;
        while valid == false
            tx = (rand()-0.5)*span; 
            ty = (rand()-0.5)*span;
            if i == 1 || all(sqrt((p_x_base(1:i-1)-tx).^2 + (p_y_base(1:i-1)-ty).^2) > 1)
                p_x_base(i) = tx; 
                p_y_base(i) = ty; 
                valid = true;
            end
        end
    end
    
    for D = D_list
        for Gap = Gap_list
            min_dist = D + Gap;
            p_x = p_x_base * min_dist;
            p_y = p_y_base * min_dist;
            
            % Metric 1: Footprint Diameter
            mean_D_swarm = (range(p_x) + range(p_y)) / 2;
            hpbw_deg = 70 * (lambda / mean_D_swarm);
            f_diam = (2 * h_geo * tan(deg2rad(hpbw_deg) / 2)) / 1000; 
            
            % Metric 2: Side Profile Analysis
            AF_side = sum(exp(1j * k_val * p_x * u_side), 1); 
            P_side = (abs(AF_side)/N).^2;
            first_drop_idx = find(P_side < 0.5, 1, 'first');
            
            if ~isempty(first_drop_idx)
                % Analyze only the "tail" of the signal after the main beam drop
                side_lobe_area = P_side(first_drop_idx:end);
                avg_side_power = mean(side_lobe_area);
            else
                avg_side_power = 0; % Fallback if beam never drops
            end
            
            results(res_idx, :) = [N, D, Gap, f_diam, avg_side_power];
            
            % --- FIXED: Now indices match [1x5] = [1x5] ---
            results(res_idx, :) = [N, D, Gap, f_diam, avg_side_power];
            res_idx = res_idx + 1;
        end
    end
    fprintf('Processed N = %d\n', N);
end

%% 3. Generate Layout (Figure 1: Footprint)
group = {results(:,1), results(:,2), results(:,3)};
varnames = {'N', 'Diam (D)', 'Gap'};

fig1 = figure('Name', 'Footprint Analysis', 'Units', 'pixels');
[~, ax1, bigax1] = interactionplot(results(:,4), group, 'VarNames', varnames);
set(bigax1, 'Units', 'normalized', 'Position', [0.15, 0.1, 0.7, 0.8]);
ylabel(bigax1, 'Mean Footprint Diameter (km)', 'FontWeight', 'bold');

%% 4. Generate Layout (Figure 2: Side Lobe Power)
fig2 = figure('Name', 'Side Lobe Analysis', 'Units', 'pixels');
[~, ax2, bigax2] = interactionplot(results(:,5), group, 'VarNames', varnames);
set(bigax2, 'Units', 'normalized', 'Position', [0.15, 0.1, 0.7, 0.8]);
ylabel(bigax2, 'Avg Side Lobe Power (u > 0.5)', 'FontWeight', 'bold');

% Apply clean ticks to both figures
all_axes = [ax1; ax2];
for i = 1:numel(all_axes)
    if isgraphics(all_axes(i))
        xticks(all_axes(i), linspace(min(all_axes(i).XLim), max(all_axes(i).XLim), 5));
        grid(all_axes(i), 'on');
    end
end