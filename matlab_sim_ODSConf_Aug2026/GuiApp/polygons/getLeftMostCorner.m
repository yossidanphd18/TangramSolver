function [rc] = getLeftMostCorner(poly_image)
   [rows, cols] = find(poly_image);
   r = max(rows);
   c = min(cols);
   if(poly_image(r,c) == 0)
     r = min(rows);
     if(poly_image(r,c) == 0)
        r = 0.5*(min(rows) + max(rows));
        r = round(r);
     end
   end
   rc = [r,c];
end