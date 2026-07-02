function appData = handleSavedDB(appData, enable_msg_box)
    if(nargin < 2)
        enable_msg_box = false;
    end

    try 
        SaveDB = struct();
        
        % Ensure Grid is included in the struct for the orientations function
        % SaveDB.Grid = appData.Grid;
        
        SaveDB.TilesInfo.FinalPlacement.Polygons = appData.Polygons;
        for k = 1:length(appData.Polygons)
            p = appData.Polygons{k};
            mask = calculateCoveredArea(p.Vertices, appData.Grid.xmin, appData.Grid.xmax, appData.Grid.ymin, appData.Grid.ymax);
            SaveDB.TilesInfo.FinalPlacement.Tiles{k} = mask;
            props.theta = p.Theta; props.flip_id = p.FlipID;
            SaveDB.TilesInfo.FinalPlacement.Properties{k} = props;
        end
        appData.SaveDB = SaveDB;
        appData = extractTrueRotsAndTrans(appData, true);
        [appData.SaveDB.FlipsRotsTiles] = get_all_base_orientations(appData.SaveDB.TilesInfo, appData.SaveDB.Grid);
        if ~exist(appData.challenge_db_save_path, 'dir'), mkdir(appData.challenge_db_save_path); end
        filename = fullfile(appData.challenge_db_save_path, [appData.puzzle_id, '_data.mat']);
        SaveDB = appData.SaveDB; % must save the most updated data!!!
        save(filename, 'SaveDB' , '-v7.3');
        if(enable_msg_box)
            % msgbox(['Data saved to ', filename], 'Success');

            msgStr = {['Data saved to ', filename]};                  
            % Use the reference to call the universal helper
            if isfield(appData, 'MainApp') && isvalid(appData.MainApp)
                appData.MainApp.showAlert(msgStr, 'SavedDB Success');
            else
                % Fallback for safety
                msgbox(msgStr, 'SavedDB Success');
            end
        end
    catch ME
        errordlg(['Save Error: ', ME.message]);            
    end 
end 