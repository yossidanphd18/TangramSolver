function [group_sizes] = extractGroupsSize(CountsDB)
    [npcs,~,~] = size(CountsDB);
    group_sizes = zeros(1,npcs);
    for k = 1:npcs
        counts = CountsDB(k,:,:);
	    nvecs = sum(counts(:));
        group_sizes(k) = nvecs;
    end
end
