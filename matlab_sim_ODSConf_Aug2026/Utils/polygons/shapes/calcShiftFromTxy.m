function [t_shift] = calcShiftFromTxy(im_dims, t_xy)

    % nr = im_dims(1);
    nc = im_dims(2);
        
    t_x = t_xy(1);
    t_y = t_xy(2);
    
    t_shift = nc*t_y + t_x;

end
