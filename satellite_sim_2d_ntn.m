function satellite_sim_2d_ntn
    % --- 1. Physics & Constants ---
    f = 2.1e9;                
    c = 299792458; 
    lambda = c/f;             
    h_geo = 35786000;         
    %bandwidth = 200e3; %200Khz for one Subcarrier   
    %tx_power_watts = 100;     
    
    %% Start Values
    N = 20;                  
    D = 2.0;
    Gap = 30.0; 
    Long = 0;
    Lat = 0;
    
    %% Setup Figure
    fig = figure('Name', 'NTN Analysis: Footprint Diameter & Profile', ...
                 'Color', 'w', 'Position', [50 50 1500 900]);
    
    g = uigridlayout(fig, [3, 3]);
    g.RowHeight = {'fit', '0.5x', '1.5x'}; 
    g.ColumnWidth = {'1x', '1.1x', '1x'};
    
    %% Controls Panel
    pnl_ctrl = uipanel(g, 'Title', 'System Parameters', 'BackgroundColor', 'w');
    pnl_ctrl.Layout.Row = 1; 
    pnl_ctrl.Layout.Column = [1 3];
    gl_ctrl = uigridlayout(pnl_ctrl, [1, 6]);
    
    uilabel(gl_ctrl, 'Text', 'Satellites (N):','FontSize', 14, HorizontalAlignment='right');
    sld_N = uislider(gl_ctrl, 'Limits', [15 100], 'Value', N, 'ValueChangedFcn', @(~,~) updatePlot(),'Step',5);
    
    uilabel(gl_ctrl, 'Text', 'Diameter (D):', 'FontSize', 14, HorizontalAlignment='right');
    sld_D = uislider(gl_ctrl, 'Limits', [0.5 10], 'Value', D, 'ValueChangedFcn', @(~,~) updatePlot());

    uilabel(gl_ctrl, 'Text', 'Min Gap (m):', 'FontSize', 14, HorizontalAlignment='right'); 
    sld_Gap = uislider(gl_ctrl, 'Limits', [30 2000], 'Value', Gap, 'ValueChangedFcn', @(~,~) updatePlot(), 'Step',20);

    %% Stats/Positions Row
    ax_pos = axes(g); 
    ax_pos.Layout.Row = 3; 
    ax_pos.Layout.Column = 3;
    title(ax_pos, 'Array Geometry (m)');
    
    pnl_res = uipanel(g, 'Title', 'Link Stats', 'BackgroundColor', 'w', FontSize= 14);
    pnl_res.Layout.Row = 2; 
    pnl_res.Layout.Column = [1 3];
    gl_res = uigridlayout(pnl_res, [4, 3]);
    lbl_N = uilabel(gl_res, 'Text', 'Number of Satellites: --', 'FontSize', 14, 'FontWeight', 'bold');
    lbl_N.Layout.Row = 1;
    lbl_N.Layout.Column = 3;
    lbl_D = uilabel(gl_res, 'Text', 'Diameter of Satellites --', 'FontSize', 14,'FontWeight', 'bold');
    lbl_D.Layout.Row = 2;
    lbl_D.Layout.Column = 3;
    lbl_HPBW = uilabel(gl_res, 'Text', 'HPBW Diam: -- deg', 'FontSize', 14, 'FontWeight', 'bold');
    lbl_HPBW.Layout.Row = 3;
    lbl_HPBW.Layout.Column = 2;
    lbl_Diam = uilabel(gl_res, 'Text', 'Footprint Diam: -- km', 'FontSize', 14, 'FontWeight', 'bold');
    lbl_Diam.Layout.Row = 4;
    lbl_Diam.Layout.Column = 2;
    lbl_Gap = uilabel(gl_res, 'Text', 'Minimum Gap -- m', 'FontSize', 14, 'FontWeight', 'bold');
    lbl_Gap.Layout.Row = 3;
    lbl_Gap.Layout.Column = 3;
    lbl_Long = uilabel(gl_res, 'Text', 'X-Offset of Beam (m)', 'FontSize', 14, 'FontWeight', 'bold', HorizontalAlignment='right')
    lbl_Long.Layout.Row = 1;
    lbl_Long.Layout.Column = 1;
    ef_Long = uieditfield(gl_res, "numeric", "Limits", [-1e6 1e6],"Value", Long ,"ValueChangedFcn", @(~,~) updatePlot());
    ef_Long.Layout.Row = 1;
    ef_Long.Layout.Column = 2;
    lbl_Lat = uilabel(gl_res, 'Text', 'Y-Offset of Beam (m)', 'FontSize', 14, 'FontWeight', 'bold', HorizontalAlignment='right');
    lbl_Lat.Layout.Row = 2;
    lbl_Lat.Layout.Column = 1;
    ef_Lat = uieditfield(gl_res, "numeric", "Limits", [-1e6 1e6], "Value", Lat ,"ValueChangedFcn", @(~,~) updatePlot());
    ef_Lat.Layout.Row = 2;
    ef_Lat.Layout.Column = 2;

    %% MAIN VISUALS
    ax_foot = axes(g); 
    ax_foot.Layout.Row = 3; 
    ax_foot.Layout.Column = 1;
    title(ax_foot, 'Ground Footprint');
    
    ax_side = axes(g); ax_side.Layout.Row = 3; ax_side.Layout.Column = 2;
    title(ax_side, 'Side Profile (0° to 90°)');

    updatePlot();

    %% 3. Update Logic
    function updatePlot()
        try
            curr_N = round(sld_N.Value);
            curr_D = sld_D.Value;
            curr_Gap = sld_Gap.Value;
            curr_Long = ef_Long.Value;
            curr_Lat = ef_Lat.Value;
            
            %% Random Satellite Positions 
            min_dist = curr_D + curr_Gap; 
            p_x = zeros(curr_N, 1);
            p_y = zeros(curr_N, 1);
            span = sqrt(curr_N) * (min_dist) * 1.5;
            for i = 1:curr_N
                v = false;
                while v == false
                    tx = (rand()-0.5)*span; 
                    ty = (rand()-0.5)*span;
                    if i==1
                        v=true; 
                    else
                        if all(sqrt((p_x(1:i-1)-tx).^2 + (p_y(1:i-1)-ty).^2) > min_dist)
                            v=true; 
                        end
                    end
                    p_x(i)=tx; p_y(i)=ty;
                end
            end
            %% Calculate 2D Beam Pattern
            r_km = 500; 
            res = 1200; %resolution of Plot 
            kx = linspace(-r_km, r_km, res); %in km 
            ky = linspace(-r_km, r_km, res); %in km
            [KX, KY] = meshgrid(kx, ky);
            U = (KX*1000)/h_geo;
            V = (KY*1000)/h_geo;
            AF = zeros(size(U));
            k_val = 2*pi/lambda;
            for i = 1:curr_N
                AF = AF + exp(1j * k_val * (p_x(i)*U + p_y(i)*V));  %Array Factor for 2D
            end
            P_linear = (abs(AF)/curr_N).^2;
                

            %% Steering Vector + Weight Calculation
            % Target Point on Earth
            target_x = curr_Long; %in m
            target_y = curr_Lat; %in m
            u_t = target_x / h_geo; %small angle calculation
            v_t = target_y / h_geo; %small angle calulcation
            h0 = exp(1j * k_val * (p_x * u_t + p_y * v_t));
            w = h0 / curr_N;
            AF_w = zeros(size(U));
            for i = 1:curr_N
                % Each satellite contribution is multiplied by its specific weight conjugate [cite: 17, 20]
                AF_w = AF_w + conj(w(i)) * exp(1j * k_val * (p_x(i)*U + p_y(i)*V));
            end
            P_linear_w = (abs(AF_w)).^2;

            %% Side Profile (0 to 90 degrees)
            theta_deg = linspace(0, 90, 2000); 
            theta_rad = deg2rad(theta_deg);
            u_side = sin(theta_rad);
            AF_side = zeros(size(u_side));
            for i = 1:curr_N
                AF_side = AF_side + exp(1j * k_val * p_x(i) * u_side); %Array Factor for X-Side
            end
            P_side = (abs(AF_side)/curr_N).^2;

            %% Footprint
            cla(ax_foot); 
            hold(ax_foot, 'on');
            imagesc(ax_foot, kx, ky, 10*log10(P_linear_w + 1e-5));
            xtickformat(ax_foot, '%.4g') 
            ytickformat(ax_foot, '%.4g')
            ax_foot.XAxis.Exponent = 0;
            ax_foot.YAxis.Exponent = 0;
            ax_foot.XTickLabelRotation = 45;
            colormap(ax_foot, 'jet'); 
            [C, ~] = contour(ax_foot, kx, ky, P_linear_w, [0.5 0.5], 'r', 'LineWidth', 2);

            
            %% Footprint Calculation
            mean_D_swarm = (((max(p_x) - min(p_x))+(max(p_y) - min(p_y)))/2); % km
            hpbw_deg = 70 * (lambda / mean_D_swarm);
            hpbw_rad = deg2rad(hpbw_deg);
            f_diam = (2 * h_geo * tan(hpbw_rad / 2)) / 1000;

            axis(ax_foot, 'square'); 
            grid(ax_foot, 'on');
            
            %% Side Profile Plot
            cla(ax_side); hold(ax_side, 'on');
            plot(ax_side, theta_deg, P_side, 'LineWidth', 1.5, 'Color', [0 0.447 0.741]);
            yline(ax_side, 0.5, 'r--', '-3dB');
            xlabel(ax_side, 'Angle (deg)'); ylabel(ax_side, 'Normalized Power');
            grid(ax_side, 'on'); xlim(ax_side, [0 90]); ylim(ax_side, [0 1.1]);

            %% Update Labels
            lbl_HPBW.Text = sprintf('HPBW: %.2f deg', hpbw_deg);
            lbl_Diam.Text = sprintf('Footprint Diam: %.2f km', f_diam);
            lbl_N.Text = sprintf('Number of Satellites %i', curr_N);
            lbl_D.Text = sprintf('Diameter of Satellites: %.2f', curr_D);
            lbl_Gap.Text = sprintf('Minimum Gap: %.2f', curr_Gap);
            
            
          

            %% Positions Plot
            cla(ax_pos); 
            hold(ax_pos, 'on');
            for i=1:curr_N
                rectangle(ax_pos, 'Position', [p_x(i)-curr_D/2, p_y(i)-curr_D/2, curr_D*((mean_D_swarm)/100), curr_D*((mean_D_swarm)/100)], ...
                          'Curvature', [1 1], 'FaceColor', [0 .45 .74 .3]);
            end
            axis(ax_pos, 'equal'); 
            grid(ax_pos, 'on');

        catch ME
            fprintf('Update Error: %s\n', ME.message);
        end
    end
end