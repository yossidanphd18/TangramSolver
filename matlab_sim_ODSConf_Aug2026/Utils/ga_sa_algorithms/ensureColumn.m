function x_col = ensureColumn(x)
    % Converts any vector (row or column) into a column vector.
    % If x is already a column vector, it remains unchanged.
    
    x_col = x(:);
end