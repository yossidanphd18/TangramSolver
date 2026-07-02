function [p_xi] = get_xi_index(flag_which_part, kpiece, krot, xfirst, npcs, GP)
    
	
    if(flag_which_part ~= 2)
        p1 = xfirst + (krot-1)*(GP.vdim*npcs) ;
        p_xi = p1 + (kpiece-1)*GP.vdim;
    else
        p_xi = xfirst + (kpiece - 1)*(GP.vdim) ;
    end

end