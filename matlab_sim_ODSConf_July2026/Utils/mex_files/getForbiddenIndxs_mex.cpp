#include "mex.h"
#include <vector>

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    // Inputs: BasisVectors (DxN), threshold (scalar)
    double *basis = mxGetPr(prhs[0]);
    size_t D = mxGetM(prhs[0]); // Vector dimension
    size_t N = mxGetN(prhs[0]); // Number of vectors
    double threshold = mxGetScalar(prhs[1]);

    // Output: cell array of indices
    plhs[0] = mxCreateCellMatrix(1, N);

    for (size_t i = 0; i < N; ++i) {
        std::vector<double> forbidden;
        for (size_t j = 0; j < N; ++j) {
            if (i == j) continue;

            // Count intersections: values >= 1.0
            int K = 0;
            for (size_t d = 0; d < D; ++d) {
                // if (basis[i * D + d] >= 1.0 && basis[j * D + d] >= 1.0) {
				if ((basis[i * D + d] + basis[j * D + d]) > 1.05) {	
                    K++;
                }
            }

            if (K > threshold) {
                forbidden.push_back(j + 1); // +1 for MATLAB 1-based indexing
            }
        }

        // Copy vector to cell array
        mxArray *cell_array = mxCreateDoubleMatrix(1, forbidden.size(), mxREAL);
        double *data = mxGetPr(cell_array);
        for (size_t k = 0; k < forbidden.size(); ++k) {
            data[k] = forbidden[k];
        }
        mxSetCell(plhs[0], i, cell_array);
    }
}