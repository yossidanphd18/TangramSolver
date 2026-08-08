function [group_sizes, D_groups] = extractGroupsInfo(CountsDB, BasisVectors)
    [npcs,~,~] = size(CountsDB);
    group_sizes = [];
    D_groups = cell(1, npcs);
    p1 = 1;
    for k = 1:npcs
        counts = CountsDB(k,:,:);
	    nvecs = sum(counts(:));
	    p2 = p1 + nvecs - 1;
        D_groups{k} = BasisVectors(:,p1:p2); 
	    p1 = p2 + 1;
        group_sizes(k) = nvecs;
    end
end
