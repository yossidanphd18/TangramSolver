function [Challenges] = create_challenges_poly(ChallengeModel)
    
    % Load the pre-saved data (saved from the Polygons GUI APP)
    pw = 1;
    names = {};
    grids = {};
    goals = {};
    
    names{pw} = ChallengeModel.puzzle_id;
    grids{pw} = ChallengeModel.Grid;
    goals{pw} = ChallengeModel.Goal;
    pw = pw + 1;
        
    %=============================
    N = length(names);
    names = reshape(names,N,[]);
    grids = reshape(grids,N,[]);

    Challenges = [];
    Challenges.Names = names;
    Challenges.Grids = grids;
    Challenges.Goals = goals;
end
