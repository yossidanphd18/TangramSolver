function [challengeData] = loadTrueResult(challengesPath, challenge_name)
    challengeData = [];

    matFile = fullfile(challengesPath, [char(challenge_name),'_data.mat']);
    if isfile(matFile)
        data = load(matFile);
        challengeData = data.SaveDB;
    end
end
