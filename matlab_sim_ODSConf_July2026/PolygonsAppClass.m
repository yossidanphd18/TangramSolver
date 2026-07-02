classdef PolygonsAppClass < handle
    properties
        appData % This replaces the old UserData struct
        Figure  % The main figure handle
    end
    
    methods
        % --- CONSTRUCTOR ---
        function obj = PolygonsAppClass(user_params)
            
            assert(~isempty(user_params),'Expecting user_params structure as input. Please fix!');

			% user parameters
			obj.appData.user_params = user_params;
            
            obj.appData.isWeb = user_params.use_web_mode;

            % 1. Initial Configuration
            obj.appData.challenge_type = 'polygons';
            obj.appData.puzzle_id = 'shape56'; 

            % 2. Environment Setup
            obj.setupPaths();
                        
            % Initial State
            obj.appData.Polygons = cell(0); 
            obj.appData.ActivePolygonIndex = 1; 
            obj.appData.isDragging = false;
            obj.appData.dragPolygonIndex = 0;
            obj.appData.stopRequested = false; 
            obj.appData.blinkCounter = 0;
            obj.appData.center_marker = 2; 
            obj.appData.center_marker_thresh = 1.2; 
            obj.appData.handleFeasFig = [];
            obj.appData.BaseVrtxs = cell(7,1); 
            obj.appData.showSolution = 0; % show the solution to the puzzle ?
            			            
            obj.appData.cameraDistortionParams.enabled = 0;
            obj.appData.cameraDistortionParams.intensity = 0.17;
            obj.appData.cameraDistortionParams.inflate_ratio = 1.02;
             
            obj.appData.flag_save_db = 1;
            obj.appData.flag_load_polygons = 1;
            obj.appData.flag_apply_feasibility_check = 1;

            % 3. Build the GUI
            obj.buildGUI();
            
            %---------------------------------------
            % Sync UI with Initial State ---
            % Find the index of the default puzzle_id in the list of available files
            % Retrieve the list of items from the UI component directly
            if obj.appData.isWeb
                items = obj.appData.hShapeSelector.Items;
                idx = find(strcmp(items, obj.appData.puzzle_id));
                if ~isempty(idx)
                    obj.appData.hShapeSelector.Value = items{idx};
                end
            else
                items = get(obj.appData.hShapeSelector, 'String');
                idx = find(strcmp(items, obj.appData.puzzle_id));
                if ~isempty(idx)
                    set(obj.appData.hShapeSelector, 'Value', idx);
                end
            end            
            % ---------------------------------------

            % 4. Final Initializations
            % scale_gain = 1.0;
            % Call external update function
            % obj.appData = updateProblemParams(obj.appData, scale_gain, 1, 1, 1);
            obj.appData = updateProblemParams(obj.appData);

            % Note - more parameters set in updateProblemParams() ,
            % prepareSimParams().
            obj.appData.MainApp = obj;
        end
        
        function updateLabel(obj, handle, newString)
            if obj.appData.isWeb
                handle.Text = newString;   % Modern UI (Web)
            else
                handle.String = newString; % Legacy UI (Desktop)
            end
        end

        function showAlert(obj, message, title)
            % fprintf('[%s] %s\n', title, message);
            % fprintf('[%s] %s\n', title, strjoin(message, ':'));

            % Force message into a cell array if it's a plain character vector
            if ischar(message)
                message = {message}; 
            end
            
            fprintf('[%s] %s\n', title, strjoin(message, ':'));

            if obj.appData.isWeb
                uialert(obj.Figure, message, title);
            else
                msgbox(message, title);
            end
        end

        % function showAlert(obj, message, title)
        %     if obj.appData.isWeb
        %         % uiconfirm is the Web-compatible way to show alerts
        %         % It requires a handle to the uifigure
        %         uiconfirm(obj.Figure, message, title, ...
        %             'Options', {'OK'}, 'Icon', 'info');
        %     else
        %         % Standard desktop pop-up
        %         msgbox(message, title);
        %     end
        % end

        function setupPaths(obj)
            % Use ctfroot for compiled Web Apps to locate files correctly
            % if isdeployed
            %     mainPath = ctfroot; 
            % else
                mainPath = fileparts(mfilename('fullpath'));
            % end
            
            folders = {'Utils', 'Challenges', 'Perf', 'GuiApp'};
            for i = 1:length(folders)
                targetFolder = fullfile(mainPath, folders{i});
                if exist(targetFolder, 'dir')
                    addpath(genpath(targetFolder));
                end
            end

            if(strcmp(obj.appData.challenge_type,'polygons'))
                targetFolder = fullfile(mainPath, '/GuiApp/lattice/');
                rmpath(genpath(targetFolder));
                targetFolder = fullfile(mainPath, '/Utils/lattice/');
                rmpath(genpath(targetFolder));
                targetFolder = fullfile(mainPath, '/Perf/lattice/');
                rmpath(genpath(targetFolder));
            end

            addpath(genpath('C:/gurobi1203/win64/matlab/'));

        end
        
        function buildGUI(obj)
            % --- SCREEN SIZING ---
            screenSize = get(0, 'ScreenSize'); 
            figWidth = screenSize(3) * 0.9;
            figHeight = screenSize(4) * 0.8;
            figPos = [(screenSize(3)-figWidth)/2, (screenSize(4)-figHeight)/2, figWidth, figHeight];

            % 1. Create Figure based on mode
            if obj.appData.isWeb
                obj.Figure = uifigure('Name', 'Polygon Grid Coverage (Web)', ...
                    'Position', figPos, 'Color', [0.15 0.15 0.15]);
            else
                obj.Figure = figure('Name', 'Polygon Grid Coverage (Desktop)', ...
                    'NumberTitle', 'off', 'Position', figPos, ...
                    'MenuBar', 'none', 'ToolBar', 'figure', 'Color', [0.15 0.15 0.15], ...
                    'HandleVisibility', 'on');
            end
            
            % --- PANELS ---
            % Panels work similarly in both, but foreground/background color handling varies
            obj.appData.hControlPanel = uipanel(obj.Figure, 'Title', 'DASHBOARD', 'FontSize', 10, ...
                'FontWeight', 'bold', 'ForegroundColor', 'white', 'BackgroundColor', [0.2 0.2 0.2], ...
                'Units', 'normalized', 'Position', [0.01 0.01 0.18 0.98]);
            
            visPanel = uipanel(obj.Figure, 'Title', 'POLYGON WORKSPACE', 'FontSize', 10, ...
                'FontWeight', 'bold', 'ForegroundColor', 'white', 'BackgroundColor', [0.25 0.25 0.25], ...
                'Units', 'normalized', 'Position', [0.2 0.01 0.79 0.98]);
            
            % --- AXES ---
            % Web Apps require 'uiaxes' for best performance, but 'axes' works in compatibility mode
            if obj.appData.isWeb
                ax_poly = uiaxes(visPanel, 'Position', [0.03 0.04 0.46 0.93], 'BackgroundColor', [0.1 0.1 0.1], 'XColor', 'w', 'YColor', 'w');
                ax_heat = uiaxes(visPanel, 'Position', [0.51 0.04 0.46 0.93], 'BackgroundColor', [0.1 0.1 0.1], 'XColor', 'w', 'YColor', 'w');
            else
                ax_poly = axes(visPanel, 'Position', [0.03 0.04 0.46 0.93], 'Color', [0.1 0.1 0.1], 'XColor', 'w', 'YColor', 'w');
                ax_heat = axes(visPanel, 'Position', [0.51 0.04 0.46 0.93], 'Color', [0.1 0.1 0.1], 'XColor', 'w', 'YColor', 'w');
            end
            
            hold(ax_poly, 'on'); grid(ax_poly, 'on');
            obj.appData.ax_poly_handle = ax_poly;
            obj.appData.ax_heat_handle = ax_heat;
            % linkaxes works for both
            linkaxes([ax_poly, ax_heat], 'xy');
            
            % --- UI CONTROLS SETUP ---
            yTop = 0.94;
            allFiles = dir('**/createShape_*.m');
            cleanNames = cellfun(@(x) strrep(strrep(x, 'createShape_', ''), '.m', ''), {allFiles.name}, 'UniformOutput', false);
            
            if obj.appData.isWeb
                % --- WEB UI COMPONENTS (uifigure style) ---
                % Note: Positions are [left bottom width height] in pixels.
                % We use (yTop - offset) * figHeight to place components relative to the top.
            
                % Dropdown
                obj.appData.hShapeSelector = uidropdown(obj.appData.hControlPanel, ...
                    'Position', [10, (yTop-0.05)*figHeight, 160, 25], ...
                    'Items', cleanNames, 'ValueChangedFcn', @obj.wrapper_shapeSelector);
                
                % Save Button
                obj.appData.hSaveBtn = uibutton(obj.appData.hControlPanel, ...
                    'Text', 'SAVE DATA', ...
                    'Position', [10, (yTop-0.12)*figHeight, 160, 0.06*figHeight], ...
                    'BackgroundColor', [0.8 0.4 0.1], 'FontColor', 'w', 'FontWeight', 'bold', ...
                    'ButtonPushedFcn', @obj.wrapper_output);
            
                % Show Solution Button
                obj.appData.hShowBtn = uibutton(obj.appData.hControlPanel, ...
                    'Text', 'SHOW SOLUTION', ...
                    'Position', [10, (yTop-0.20)*figHeight, 160, 0.06*figHeight], ...
                    'BackgroundColor', [0.2 0.4 0.6], 'FontColor', 'w', 'FontWeight', 'bold', ...
                    'ButtonPushedFcn', @obj.wrapper_toggleSolution);
            
                % Start Solver Button
                obj.appData.hStartBtn = uibutton(obj.appData.hControlPanel, ...
                    'Text', 'START SOLVER', ...
                    'Position', [10, (yTop-0.28)*figHeight, 160, 0.06*figHeight], ...
                    'BackgroundColor', [0.1 0.5 0.1], 'FontColor', 'w', 'FontWeight', 'bold', ...
                    'ButtonPushedFcn', @obj.wrapper_startSolver);
            
                % Night Mode Button (Renamed from second hStartBtn to avoid overwriting)
                obj.appData.hNightBtn = uibutton(obj.appData.hControlPanel, ...
                    'Text', 'NIGHT MODE', ...
                    'Position', [10, (yTop-0.36)*figHeight, 160, 0.06*figHeight], ...
                    'BackgroundColor', [0.1 0.3 0.6], 'FontColor', 'w', 'FontWeight', 'bold', ...
                    'ButtonPushedFcn', @obj.wrapper_solveAll);
            
                % Stop Solver Button
                obj.appData.hStopBtn = uibutton(obj.appData.hControlPanel, ...
                    'Text', 'STOP SOLVER', ...
                    'Position', [10, (yTop-0.44)*figHeight, 160, 0.06*figHeight], ...
                    'BackgroundColor', [0.7 0.1 0.1], 'FontColor', 'w', 'FontWeight', 'bold', 'Enable', 'off', ...
                    'ButtonPushedFcn', @obj.wrapper_stopSolver);
            
                % Status Text
                obj.appData.hStatusText = uilabel(obj.appData.hControlPanel, ...
                    'Text', '', ...
                    'Position', [10, (yTop-0.58)*figHeight, 160, 0.12*figHeight], ...
                    'FontColor', 'y', 'FontWeight', 'bold', 'Visible', 'off');
                
                % Heuristic Value Text
                obj.appData.hHeurValueText = uilabel(obj.appData.hControlPanel, ...
                        'Text', 'Value: 0.05', ...
                        'Position', [10, (yTop-0.63)*figHeight, 160, 0.02*figHeight], 'FontColor', 'y');
            
                % Heuristic Slider
                obj.appData.hHeurSlider = uislider(obj.appData.hControlPanel, ...
                    'Position', [20, (yTop-0.61)*figHeight, 140, 3], ...
                    'Limits', [0.05 0.95], 'Value', 0.05, 'ValueChangedFcn', @obj.wrapper_slider);

            else
                % --- DESKTOP UI COMPONENTS (uicontrol style) ---
                obj.appData.hShapeSelector = uicontrol(obj.appData.hControlPanel, 'Style', 'popupmenu', ...
                    'Units', 'normalized', 'Position', [0.05 yTop-0.05 0.9 0.04], ...
                    'String', cleanNames, 'Callback', @obj.wrapper_shapeSelector);
                
                obj.appData.hSaveBtn = uicontrol(obj.appData.hControlPanel, 'Style', 'pushbutton', ...
                    'String', 'SAVE DATA', 'Units', 'normalized', 'Position', [0.05 yTop-0.12 0.9 0.06], ...
                    'BackgroundColor', [0.8 0.4 0.1], 'ForegroundColor', 'w', 'FontWeight', 'bold', ...
                    'Callback', @obj.wrapper_output);
                
                obj.appData.hShowBtn = uicontrol(obj.appData.hControlPanel, 'Style', 'pushbutton', ...
                    'String', 'SHOW SOLUTION', 'Units', 'normalized', 'Position', [0.05 yTop-0.20 0.9 0.06], ...
                    'BackgroundColor', [0.2 0.4 0.6], 'ForegroundColor', 'w', 'FontWeight', 'bold', ...
                    'Callback', @obj.wrapper_toggleSolution);

                obj.appData.hStartBtn = uicontrol(obj.appData.hControlPanel, 'Style', 'pushbutton', ...
                    'String', 'START SOLVER', 'Units', 'normalized', 'Position', [0.05 yTop-0.28 0.9 0.06], ...
                    'BackgroundColor', [0.1 0.5 0.1], 'ForegroundColor', 'w', 'FontWeight', 'bold', ...
                    'Callback', @obj.wrapper_startSolver);

                 obj.appData.hStartBtn = uicontrol(obj.appData.hControlPanel, 'Style', 'pushbutton', ...
                    'String', 'NIGHT MODE', 'Units', 'normalized', 'Position', [0.05 yTop-0.36 0.9 0.06], ...
                    'BackgroundColor', [0.1 0.3 0.6], 'ForegroundColor', 'w', 'FontWeight', 'bold', ...
                    'Callback', @obj.wrapper_solveAll);
               
                obj.appData.hStatusText = uicontrol(obj.appData.hControlPanel, 'Style', 'text', 'String', '', ...
                    'Units', 'normalized', 'Position', [0.05 yTop-0.58 0.9 0.12], ...
                    'BackgroundColor', [0.2 0.2 0.2], 'ForegroundColor', 'y', 'FontWeight', 'bold', 'Visible', 'off');

                obj.appData.hHeurValueText = uicontrol(obj.appData.hControlPanel, 'Style', 'text', ...
                        'String', 'Value: 0.05', 'Units', 'normalized', ...
                        'Position', [0.05 yTop-0.63 0.9 0.02], 'BackgroundColor', [0.2 0.2 0.2], 'ForegroundColor', 'y');

                obj.appData.hHeurSlider = uicontrol(obj.appData.hControlPanel, 'Style', 'slider', ...
                    'Units', 'normalized', 'Position', [0.05 yTop-0.61 0.9 0.03], ...
                    'Min', 0.05, 'Max', 0.95, 'Value', 0.05, 'Callback', @obj.wrapper_slider);

                obj.appData.hStopBtn = uicontrol(obj.appData.hControlPanel, 'Style', 'pushbutton', ...
                        'String', 'STOP SOLVER', 'Units', 'normalized', 'Position', [0.05 yTop-0.44 0.9 0.06], ...
                        'BackgroundColor', [0.7 0.1 0.1], 'ForegroundColor', 'w', 'FontWeight', 'bold', 'Enable', 'off', ...
                        'Callback', @obj.wrapper_stopSolver);                
            end

            % --- TIMER (Same for both) ---
            obj.appData.blinkTimer = timer('ExecutionMode', 'fixedRate', 'Period', 0.5, ...
                'TimerFcn', @(src, event) obj.wrapper_timerBlink(src, event));
        end

        % --- COMPATIBILITY WRAPPERS ---
        % These call your existing .m files with minimal changes.
        
        function wrapper_output(obj, src, ev), obj.appData = output_Callback(src, ev, obj.appData); end
        function wrapper_shapeSelector(obj, src, ev), obj.appData = shapeSelector_Callback(src, ev, obj.appData); end
        function wrapper_toggleSolution(obj, src, ev), obj.appData = toggleSolution_Callback(src, ev, obj.appData); end
        function wrapper_startSolver(obj, src, ev), obj.appData = startSolver_Callback(src, ev, obj.appData); end
        function wrapper_stopSolver(obj, src, ev), obj.appData = stopSolver_Callback(src, ev, obj.appData); end
        function wrapper_solveAll(obj, src, ev), obj.appData = solveAll_Callback(src, ev, obj.appData); end

        function wrapper_mouseDown(obj, src, ev), obj.appData = mouseDown_Callback(src, ev, obj.appData); end
        function wrapper_mouseMove(obj, src, ev), obj.appData = mouseMove_Callback(src, ev, obj.appData); end
        function wrapper_mouseUp(obj, src, ev), obj.appData = mouseUp_Callback(src, ev, obj.appData); end
        
        function wrapper_slider(obj, src, ~)
            val = get(src, 'Value');
            set(obj.appData.hHeurValueText, 'String', sprintf('Value: %.2f', val));
        end

        function wrapper_timerBlink(obj, ~, ~)
            if isempty(obj.Figure) || ~isvalid(obj.Figure)
                return; 
            end
            
            try
                % 1. Run the math/logic
                obj.appData = timerBlink_Wrapper(obj.Figure, [], obj.appData);
                
                % 2. Update UI using the Universal helper (SAFE FOR BOTH)
                msg = sprintf('Blink Count: %d', obj.appData.blinkCounter);
                obj.updateLabel(obj.appData.hStatusText, msg);
                
            catch ME
                stop(obj.appData.blinkTimer);
                fprintf('Timer Error: %s\n', ME.message);
            end
        end
        
        function onClose(obj, ~, ~)
            try stop(obj.appData.blinkTimer); catch; end
            delete(obj.appData.blinkTimer);
            delete(obj.Figure);
        end
    end
end