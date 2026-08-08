function [p_ai] = get_ai_index(kpiece, krot, afirst, nrots)
    p1 = afirst + (kpiece-1)*nrots ;
    p_ai = p1 + krot - 1;
end