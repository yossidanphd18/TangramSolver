function [covered_areas_matrix] = calculateCoveredArea(polygon_vertices, grid_xmin, grid_xmax, grid_ymin, grid_ymax, flag_quantize_pix_area)

if(nargin < 6)
    flag_quantize_pix_area = 0;
end
    
    num_cols = grid_xmax - grid_xmin;
    num_rows = grid_ymax - grid_ymin;
    covered_areas_matrix = zeros(num_rows, num_cols);

    min_px = floor(min(polygon_vertices(:, 1)));
    max_px = ceil(max(polygon_vertices(:, 1)));
    min_py = floor(min(polygon_vertices(:, 2)));
    max_py = ceil(max(polygon_vertices(:, 2)));

    x_start = max(grid_xmin + 1, min_px);
    x_end   = min(grid_xmax, max_px);
    y_start = max(grid_ymin + 1, min_py);
    y_end   = min(grid_ymax, max_py);

    for x_idx = x_start : x_end
        for y_idx = y_start : y_end
            
            x_min = x_idx - 1;
            y_min = y_idx - 1;
            
            cell_vertices = [
                x_min, y_min;
                x_min + 1, y_min;
                x_min + 1, y_min + 1;
                x_min, y_min + 1;
            ];
            
            intersection_poly = sutherland_hodgman_clip_local(polygon_vertices, cell_vertices);
            
            if size(intersection_poly, 1) >= 3
                area = poly_area_local(intersection_poly);                
                
                % quantization.
                if(flag_quantize_pix_area)
                    area = max(0, min(1.0, area)); % clamp to [0,1.0]
				    nbits = 8; 
				    nq = 2^nbits-1;
				    area = floor(area*nq)/nq;
                end

                row = y_idx - grid_ymin;
                col = x_idx - grid_xmin;
                covered_areas_matrix(row, col) = area;
            end
        end
    end
    
end

function clipped_poly = sutherland_hodgman_clip_local(subject_poly, clip_poly)
    clipped_poly = subject_poly;
    num_clip_edges = size(clip_poly, 1);
    
    for i = 1:num_clip_edges
        p1 = clip_poly(i, :);
        p2 = clip_poly(mod(i, num_clip_edges) + 1, :); 
        
        input_poly = clipped_poly;
        if isempty(input_poly); break; end 
        
        output_poly = [];
        num_sub_vertices = size(input_poly, 1);
        
        for j = 1:num_sub_vertices
            s = input_poly(j, :);
            e = input_poly(mod(j, num_sub_vertices) + 1, :); 
            
            % Signed distance check for 'inside'
            cross_prod_s = ((p2(1)-p1(1)) * (s(2)-p1(2)) - (p2(2)-p1(2)) * (s(1)-p1(1)));
            cross_prod_e = ((p2(1)-p1(1)) * (e(2)-p1(2)) - (p2(2)-p1(2)) * (e(1)-p1(1)));

            % CRITICAL FIX: The clip polygon (unit square) is CCW. INSIDE is non-negative (>= 0).
            % We use a small negative epsilon to handle floating point noise robustly.
            is_s_in = cross_prod_s >= -1e-9;
            is_e_in = cross_prod_e >= -1e-9; 
            
            if is_s_in && is_e_in      
                % Case 1: Both inside/on -> Add end point 'e'
                output_poly = [output_poly; e];
            elseif is_s_in && ~is_e_in 
                % Case 2: In -> Out -> Add intersection point
                intersection = intersect_lines_local(s, e, p1, p2);
                output_poly = [output_poly; intersection];
            elseif ~is_s_in && is_e_in 
                % Case 3: Out -> In -> Add intersection AND end point 'e'
                intersection = intersect_lines_local(s, e, p1, p2);
                output_poly = [output_poly; intersection; e];
            % Case 4: Both outside -> Add nothing
            end
        end
        clipped_poly = output_poly; % Update polygon for next clip edge
    end
end

function ip = intersect_lines_local(A, B, C, D)
    % Calculates the intersection point of line segment AB and the infinite line CD.
    x1 = A(1); y1 = A(2); x2 = B(1); y2 = B(2);
    x3 = C(1); y3 = C(2); x4 = D(1); y4 = D(2);

    den = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4);

    if abs(den) < 1e-9 
        ip = [NaN, NaN]; 
    else
        t_num = (x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4);
        t = t_num / den;
        % FIX: Corrected y-coordinate calculation
        ip = [x1 + t * (x2 - x1), y1 + t * (y2 - y1)]; 
    end
end

function area = poly_area_local(vertices)
    % Calculates the area of a polygon using the Shoelace Formula.
    x = vertices(:, 1);
    y = vertices(:, 2);
    area = 0.5 * abs(sum(x .* circshift(y, -1) - circshift(x, -1) .* y));
end
