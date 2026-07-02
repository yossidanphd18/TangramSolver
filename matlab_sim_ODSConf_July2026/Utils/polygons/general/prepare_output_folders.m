function [run_params] = prepare_output_folders(run_params)

    if(run_params.is_one_by_one_mode)
        save_folder_prefix_path = fullfile(pwd(),['Results_one_by_one_scale_', num2str(run_params.user_params.scale_gain,'%.1f')], filesep, 'SavedDB_');
        db_save_folder_path = [save_folder_prefix_path, run_params.puzzle_id, char(datetime('now'), '_yyyyMMdd_HHmmss'), filesep];
    else
        save_folder_prefix_path = fullfile(pwd(),['Results_scale_', num2str(run_params.user_params.scale_gain,'%.1f')], filesep, 'SavedDB_');
        db_save_folder_path = [save_folder_prefix_path, run_params.puzzle_id, char(datetime('now'), '_yyyyMMdd_HHmmss'), filesep];        
    end

    if ~exist(db_save_folder_path, 'dir')
        mkdir(db_save_folder_path)
    end    
    run_params.db_save_folder_path = db_save_folder_path;

end
