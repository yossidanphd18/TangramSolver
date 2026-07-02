function [sim_params] = prepareSimParams(challenge_type, puzzle_id, challenge_db_save_path, db_save_folder_path)


    assert(strcmp(challenge_type,'pentominos'), 'Error: only pentominos supported in this simulator!');
    % sim_params.challenge_type = 'polygons';
    % sim_params.challenge_type = 'pentominos';
    
    sim_params = [];

    sim_params.puzzle_id = puzzle_id;
    sim_params.challenge_type = challenge_type;
    sim_params.challenge_db_save_path = challenge_db_save_path;
    sim_params.db_save_folder_path = db_save_folder_path;

    sim_params.show_goal_figure = 1;

    sim_params.clip2roi = 0;
    
    % use 1 only for debug !!! injecting the true solution to the solver!
    sim_params.inject_true_sol = 0;

    % if set to 1 we'll skip calculation of all Forbiden indexes, 
    % and load pre-saved values.
    sim_params.skip_preprocess = 0;


    % a historical flag but we need it for now. 
    sim_params.flag_which_part = 2; 

    sim_params.flag_use_disqualified_db = 1;

    % "flag_transform_type" should be one of {'dft' , 'none'} 
    % sim_params.flag_transform_type = 'dft';
    sim_params.flag_transform_type = 'none';
    
    sim_params.flag_use_true_rots = 0;
    sim_params.flag_show_final_result_figure = 0;
    sim_params.flag_use_true_sol_hint = 0;
    sim_params.flag_use_integer_ai = 1;
    sim_params.flag_have_true_ref = 1;
    
    if(strcmp(sim_params.flag_transform_type,'dft'))
        sim_params.flag_selected_bins_mode = 'half';  % set to one of {'half' , 'all', 'dominant'}
        % sim_params.flag_selected_bins_mode = 'dominant';
        sim_params.flag_complex_valued_optim = 1;
        sim_params.flag_dominant_thresh = 0;
    else
        sim_params.flag_selected_bins_mode = 'all';
        sim_params.flag_complex_valued_optim = 0;
    end
    
    date_str = [datestr(now,'_yyyymmdd')];
    time_str = [datestr(now,'_HHMMSS')];            
    sim_params.save_path_per_test = fullfile(db_save_folder_path, ['SavedDB_', puzzle_id, date_str, time_str]);
  
end
