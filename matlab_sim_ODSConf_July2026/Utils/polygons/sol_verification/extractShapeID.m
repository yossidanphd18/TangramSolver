function id = extractShapeID(pathStr)
    % regexp looks for text between underscores
    % [^\\]+ ensures we only look at the folder name, not the parent path
    tokens = regexp(pathStr, 'SavedDB_([^_]+)_', 'tokens');
    
    if ~isempty(tokens)
        id = tokens{1}{1};
    else
        id = ''; % Return empty if no match found
    end
end