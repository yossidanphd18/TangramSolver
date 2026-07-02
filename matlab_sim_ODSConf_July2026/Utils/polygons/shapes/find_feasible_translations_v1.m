function [feasible_txy] = find_feasible_translations(Gxy, Pxy, boundary_only, grid_x_range, grid_y_range, grid_step, inflate_tol)
    [valid_region, is_line] = find_translations_robust(Gxy(:,1), Gxy(:,2), Pxy(:,1), Pxy(:,2), boundary_only, inflate_tol);

    [mask_full, xx, yy] = getCoveredArea(valid_region, grid_x_range(1), grid_x_range(2), grid_y_range(1), grid_y_range(2), grid_step, boundary_only);
    
    feasible_txy = [xx(mask_full) , yy(mask_full)];
end
