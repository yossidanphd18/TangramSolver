function [VariablesLocatorMap, block_lens_vector, block_starts_vector] = prepareVariablesLengthsDB_v3(flag_which_part, TBasisDictionary, GP)

    assert(flag_which_part == 2, 'should be called only for part2 at the moment!');
    [~, nbasis_vectors] = size(TBasisDictionary('BasisVectors'));
        
    % create a map object.
    VariablesLocatorMap = containers.Map;
    block_lens_vector = [];
    cnt = 1;
    
    % our optimization parameters vector is:
    % x = [a_1,a_2,...,a_N | q, z1,z2,...zL]
    %
    % [a_1,a_2,.....,a_N]
    len_ai_block.len = nbasis_vectors;
    len_ai_block.place = cnt; cnt = cnt+1;
    block_lens_vector(end+1) = len_ai_block.len;
    VariablesLocatorMap('len_ai_block') = len_ai_block;
    
    % [q, z1,z2,....] 
	len_qZ_block.len =  (GP.vdim + 1) ;
    len_qZ_block.place = cnt; cnt = cnt+1;
    block_lens_vector(end+1) = len_qZ_block.len;
    VariablesLocatorMap('len_qZ_block') = len_qZ_block;

    % prepare blocks start vector
    block_starts_vector = zeros(size(block_lens_vector));
    block_starts_vector(1) = 1;
    for k = 2:length(block_lens_vector)
        block_starts_vector(k) = sum(block_lens_vector(1:k-1))+1;
    end
        
end
