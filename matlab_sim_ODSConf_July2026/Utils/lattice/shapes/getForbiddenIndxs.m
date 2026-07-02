function [forbidden_indxs] = getForbiddenIndxs(self_TxyInfo, self_idx, txyInfoList)

	% for a given translation self_txy and it's index in the dictionary - find
	% which translations (and indexes) are not allowed for other pieces.
	% the motivation that if you place the current piece at location t_xy, then 
	% other pieces cannot be placed at same location (it is occupied already)!.
	self_txy = self_TxyInfo.t_xy;

    N = length(txyInfoList);
    pw = 1;
    forbidden_indxs = [];

    for n = 1:N
        
        TxyInfo = txyInfoList{n};
        t_xy = TxyInfo.t_xy;
        flag_same = (sum(abs(t_xy - self_txy)) == 0);
        
        if(flag_same & (n ~= self_idx))
            forbidden_indxs(pw) = n;
            pw = pw + 1;
        end

    end

end