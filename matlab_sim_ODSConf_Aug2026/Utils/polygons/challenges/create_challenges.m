function [Challenges, TilesInfo, FlipsRotsTiles] = create_challenges(run_params)
    Challenges = [];
    Challenges.challenge_type = run_params.challenge_type;
    TilesInfo = [];
    FlipsRotsTiles = [];
    
    save_folder_path = fullfile(pwd(),['Challenges_scale_', num2str(run_params.user_params.scale_gain,'%.1f')],'/polygons/',[run_params.puzzle_id, '_data.mat']);

    if(strcmp(run_params.challenge_type,'polygons'))
        ChallengeModel = load(save_folder_path);
        ChallengeModel = ChallengeModel.SaveDB;
        TilesInfo = ChallengeModel.TilesInfo;
        FlipsRotsTiles = ChallengeModel.FlipsRotsTiles;
        [Challenges] = create_challenges_poly(ChallengeModel);
    else
        save2mat = 0;
        [TilesInfo] = create_pentomino_tiles();
        [Challenges] = create_challenges_lattice(TilesInfo, save_folder_path, save2mat);

        error('Need to adapt the simulator to Pentominoes...');
    end
end
