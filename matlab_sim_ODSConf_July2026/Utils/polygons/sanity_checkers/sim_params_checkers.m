function sim_params_checkers(sim_params)
    if(strcmp(sim_params.challenge_type,'pentominos'))
        
        % For Pentominoes : the following need dedacted handlig:

        % (1) [FlipsRotsTiles] = get_all_possible_orientations(sim_params.challenge_type, TilesInfo, Grid);
        % (2) [Goal] = load_goal_spec(challenge_matfile, ProblemSpec.Tiles, show_goal_figure);
        
        error('Not yet ready - Need to adapt the simulator to Pentominos!');

    end
end