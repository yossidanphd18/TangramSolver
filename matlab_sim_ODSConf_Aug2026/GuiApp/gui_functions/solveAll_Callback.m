function appData = solveAll_Callback(src, ~, appData)
	% Find the main figure window that contains the button
	% fig = ancestor(src, 'figure');
    % 
	% % Pull the current appData struct out of the figure's UserData
	% appData = get(fig, 'UserData');

	appData.stopRequested = false;
	appData = setGuiBusy(appData, true);
   
	% This looks into the figure's live UserData every time it's called
	appData.run_params.stop_requested = @() get_stop_status(fig);
    
	appData.showSolution = false; 
	set(appData.hShowBtn, 'String', 'SHOW SOLUTION', 'BackgroundColor', [0.2 0.4 0.6]);
	
	shapes = appData.hShapeSelector.String;

	% if in selected mode - take only the selected shapes.
	if(appData.user_params.list_only_selected_shapes)
		shapes = shapes(appData.user_params.list_sleceted_index);
	end

	force_selected_shapes = 1;
	if(force_selected_shapes)
        % shapes = {'shape56'};
        
        shapes = {'shape35'};
        
        % shapes = {'shape13'};        
        % shapes = {'shape40','shape2', 'shape13', 'shape18','shape20',...
        %           'shape34', 'shape36', 'shape38','shape39','shape42',...
        %           'shape43', 'shape47', 'shape51','shape52','shape54',...
        %           'shape55', 'shape56', 'shape58','shape59','shape61', 'camel16'};

        % shapes = {'shape34', 'shape52', 'shape61'};
        % shapes = {'shape61'};
        % shapes = {'shape34'};
        % shapes = {'shape52'};
        % shapes = {'square1', 'shape31', 'shape60'};
        % shapes = {'square1', 'shape31', 'shape33', 'shape60', 'shape41', 'shape47', 'shape56', 'shape58_err'};
        % shapes = {'square1', 'shape31', 'shape33', 'shape34', 'shape60', 'shape61'};
        % shapes = {'square1', 'shape8'};
        % shapes = {'shape62'};

        % shapes = {'shape40', 'shape41', 'shape42', 'shape43', 'shape44', 'shape45', 'shape46', 'shape47',  'shape48','shape49',...
        %     'shape50','shape51','shape52','shape53','shape54','shape55','shape56','shape57','shape58','shape59','shape60','shape61','shape62','square1'};

		% shapes = {'shape36', 'shape37', 'shape38', 'shape39', 'shape2', 'shape26'};

		% shapes = {'camel16', 'shape2', 'shape10', 'shape13', 'shape17', 'shape18', 'shape19', 'shape20', 'shape21', 'shape22', 'shape23', ...
		%	'shape24', 'shape25', 'shape26', 'shape29', 'shape30', 'shape31', 'shape32', 'shape33', 'shape34', 'shape35', 'shape36', ...
		%	'shape37', 'shape38'};
        
		% For scale 0.8
		% shapes = {'shape21', 'shape22', 'shape25', 'shape2', 'shape30', 'shape34', 'shape35', 'shape36', 'shape39', 'shape40', 'shape41', 'shape43', ...
		%           'shape44', 'shape45', 'shape47', 'shape48', 'shape52', 'shape56', 'shape59', 'shape61', 'shape8'};
		
        % For scale 1.2
		% shapes = {'shape13', 'shape18', 'shape19', 'shape25', 'shape26', 'shape2', 'shape30', 'shape33', 'shape34', 'shape35', 'shape36', 'shape38', ...
			% 	  'shape40', 'shape41', 'shape43', 'shape44', 'shape45', 'shape46', 'shape49', 'shape52', 'shape56', 'shape57', 'shape59', 'shape61', 'shape62', 'shape8'};
	end

    num_choose1 = appData.run_params.user_params.num_choose;
    num_choose2 = num_choose1 + 8;

    if(appData.run_params.user_params.choose_N_selected_puzzles)
        % selected_idx = randperm(length(shapes), num_choose1);
        selected_idx = randperm(length(shapes), num_choose2);
        shapes = shapes(selected_idx);
		if(length(shapes) > num_choose1)
			shapes = shapes(1:num_choose1);
		end
    end

	remove_done_shapes = 0;
	if(remove_done_shapes)
        
        toRemove = {'shape2', 'shape13', 'shape18','shape20',...
                  'shape34', 'shape36', 'shape38','shape39','shape42',...
                  'shape43', 'shape47', 'shape51','shape52','shape54',...
                  'shape55', 'shape56', 'shape58','shape59','shape61', 'camel16', 'shape58_err', 'shape58_v1'};

        % toRemove = {'shape34', 'shape52', 'shape61', 'shape58_err', 'shape58_v1'};

		% toRemove = {'shape58_err', 'shape38', 'shape43', 'shape47'};
		
		% toRemove = {'camel16', 'shape2', 'shape10', 'shape13', 'shape17', 'shape18', 'shape19', 'shape20', 'shape21', 'shape22', 'shape23', ...
		% 	'shape24', 'shape25', 'shape26', 'shape29', 'shape30', 'shape31', 'shape32', 'shape33', 'shape34', 'shape35', 'shape36', ...
		% 	'shape37', 'shape38'};
		
        % toRemove = {'camel16', 'shape10', 'shape13', 'shape17', 'shape18', 'shape19', 'shape2', 'shape20', 'shape21', 'shape22', 'shape23', 'shape24', 'shape25', 'shape26', 'shape29', ...
        %    'shape30', 'shape31', 'shape32'};        
        
		% toRemove = {'shape17', 'shape26', 'shape34', 'shape35', 'shape41', 'shape61'};
        
		indexToRemove = ismember(shapes, toRemove);
		shapes = shapes(~indexToRemove);
	end

	numShapes = length(shapes);
	
	for i = 1:numShapes
        % appData = get(fig, 'UserData');
		if appData.stopRequested, break; end
		
		% Update ID and Dropdown
		appData.puzzle_id = shapes{i};
		appData.hShapeSelector.Value = i; 
		
		[appData] = handlePuzzleSpecificAspects(appData);

        appData = updateProblemParams(appData);
		% heurIntensity = appData.run_params.gurobi_params.Heuristics;
		
        % Update Text and force immediate UI refresh
		set(appData.hStatusText, 'String', sprintf('BATCH PROCESSING...\n(%d/%d): %s', i, numShapes, appData.puzzle_id), 'Visible', 'on');
		drawnow; 
		
		try
			% 5. Start Solver per each shape
		    appData = setToughnessFlag(appData);
			appData.run_params.is_one_by_one_mode = 0;
            %
            % We now use a single unified function for single-run or multi-run.
            %   [appData.run_params, ResPack1] = tangramProcessing_xN(appData.run_params);
            % So this function is redundant.
            %   [appData.run_params, ResPack1] = tangramProcessing(appData.run_params);
            %
            [appData.run_params, ResPack1] = tangramProcessing_xN(appData.run_params);
      
		catch ME
			fprintf('Error during Solving on %s: %s\n', appData.puzzle_id, ME.message);
		end
		
		% Optional: small pause to actually see the result on the GUI
		% close all;
		delete(findall(0, 'Type', 'figure', 'Tag', 'SolverFig'));
		pause(0.5); 
	end
	
	appData = setGuiBusy(appData, false);

    msgStr = 'Batch processing complete.';
    % Use the reference to call the universal helper
    if isfield(appData, 'MainApp') && isvalid(appData.MainApp)
        appData.MainApp.showAlert(msgStr, 'SolveAll Success');
    else
        % Fallback for safety        
        if(appData.isWeb)
            fprintf('---> SolveAll Success\n');
        else
            msgbox(msgStr, 'SolveAll Success');
        end
    end

	% msgbox('Batch processing complete.', 'Success');
end

function status = get_stop_status(fig)
	data = get(fig, 'UserData');
	status = data.stopRequested;
end