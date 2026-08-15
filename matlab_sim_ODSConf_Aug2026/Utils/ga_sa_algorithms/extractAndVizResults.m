function [acc_vec] = extractAndVizResults(best_indices, D_groups, image_dims)
    vecDim = prod(image_dims);
    acc_vec = zeros(vecDim,1);
    Nr = image_dims(2); 
    Nc = image_dims(1);
    %figure(10); hold on;
    for k = 1:length(best_indices)
        curr_group = D_groups{k};
        best_idx = best_indices(k);
        curr_vec = curr_group(:,best_idx);
        %imagesc(reshape(curr_vec, Nr, Nc));
        acc_vec = acc_vec + curr_vec;
    end
    figure(20); imagesc(imrotate(reshape(acc_vec, Nr, Nc), -90));
end
