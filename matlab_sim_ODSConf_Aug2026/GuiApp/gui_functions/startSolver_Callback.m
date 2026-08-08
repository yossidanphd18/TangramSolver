function appData = startSolver_Callback(src, ~, appData)

	% % Find the main figure window that contains the button
	% fig = ancestor(src, 'figure');
    % 
	% % Pull the current appData struct out of the figure's UserData
	% appData = get(fig, 'UserData');
	
	appData.stopRequested = false;
	appData = setGuiBusy(appData, true);

	% This looks into the figure's live UserData every time it's called
	appData.run_params.stop_requested = @() get_stop_status(fig);
	
	try
        appData = updateProblemParams(appData);
		heurIntensity = appData.run_params.gurobi_params.Heuristics;
		% Update Text and force immediate UI refresh
		set(appData.hStatusText, 'String', sprintf('PROCESSING (%s)...\n(heuristicsIntense = %.2f)', appData.puzzle_id, heurIntensity), 'Visible', 'on', 'ForegroundColor', [253 170 58]./255);
		drawnow; 
		appData = setToughnessFlag(appData);
		appData.run_params.is_one_by_one_mode = 1;
		
        % [appData.run_params, ResPack1] = tangramProcessing(appData.run_params);
        %
        % We now use a single unified function for single-run or multi-run.
        %   [appData.run_params, ResPack1] = tangramProcessing_xN(appData.run_params);
        % So this function is redundant.
        %   [appData.run_params, ResPack1] = tangramProcessing(appData.run_params);
        %
        [appData.run_params, ResPack1] = tangramProcessing_xN(appData.run_params);
            

		% If we want second pass.
		if(0) % NOT USED AT THE MOMENT.
			appData.user_params.scale_gain = 1.0;
			save_db = 1;
			apply_feasibility_check = 1;
			load_polygons = 1;
			appData = updateProblemParams(appData, appData.user_params.scale_gain, save_db, apply_feasibility_check, load_polygons);
			heurIntensity = appData.run_params.gurobi_params.Heuristics;
			% Update Text and force immediate UI refresh
			set(appData.hStatusText, 'String', sprintf('PROCESSING (%s)...\n(heuristicsIntense = %.2f)', appData.puzzle_id, heurIntensity), 'Visible', 'on', 'ForegroundColor', [253 170 58]./255);
			drawnow; 
			
			appData.run_params.SOLVER_RESULT = ResPack1.SOLVER_RESULT;
			[appData.run_params, ResPack2] = tangramProcessing_xN(appData.run_params);
		end

		if appData.stopRequested
            if(appData.isWeb)
			    fprintf('---> Solver stopped by the user.\n');
            else
                msgbox('Solver stopped by user.', 'Stopped');
            end
		else                    
			if isfield(appData.run_params, 'db_save_folder_path') 
				savePath = appData.run_params.db_save_folder_path;
			else
				error('Could not find run_params.db_save_folder_path!!');
			end           

            msgStr = {['Solver finished for ', appData.puzzle_id]; ...
                      ''; ['Results saved to: ', savePath]};
                  
            % Use the reference to call the universal helper
            if isfield(appData, 'MainApp') && isvalid(appData.MainApp)
                appData.MainApp.showAlert(msgStr, 'Solver Success');
            else
                % Fallback for safety
                if(appData.isWeb)
			        fprintf('---> %s\n', msgStr);
                else
                    msgbox(msgStr, 'Solver Success');
                end
            end
		end
	catch ME
		fprintf('\n=== SOLVER CRASH DETECTED ===\n');
		fprintf('%s\n', getReport(ME));
        if(appData.isWeb)
            error(['Solver Error: ', ME.message]);
        else
            errordlg(['Solver Error: ', ME.message]);
        end		
	end
	
	appData = setGuiBusy(appData, false);

	% Save the modified appData back into the figure
	% set(fig, 'UserData', appData);
end
	
function status = get_stop_status(fig)
	data = get(fig, 'UserData');
	status = data.stopRequested;
end