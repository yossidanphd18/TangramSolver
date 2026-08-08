%======================================================================
function [model] = constraint_bilinear_zxy(nvars, z_idx, x_idx, y_idx, model, cnt_idx)
%======================================================================
    % z = x*y (in my case v_i = u * t_i)
    % cnt_idx - the constraint counter
    Qc = zeros(nvars, nvars);
    q = zeros(nvars, 1);
    rhs = 0.0;
    
    Qc(y_idx, x_idx) = 1;
    q(z_idx) = -1;

    model.quadcon(cnt_idx).Qc = sparse(Qc);
    model.quadcon(cnt_idx).q  = sparse(q); 
    model.quadcon(cnt_idx).rhs = rhs;
    model.quadcon(cnt_idx).sense = '=';
end