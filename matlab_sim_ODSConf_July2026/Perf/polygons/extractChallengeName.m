function [challenge_name] = extractChallengeName(folderName)
    % Splits "SavedDB_camel16_2025..." by underscore and takes the 2nd part
    challenge_name = '';
    parts = strsplit(folderName, '_');
    if length(parts) >= 2
        challenge_name = string(parts{2}); 
    else
        challenge_name = string(folderName); % Fallback
    end
end
