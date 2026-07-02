#include "mex.h"
#include <vector>
#include <omp.h> // Include OpenMP

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    double *basis = mxGetPr(prhs[0]);
    size_t D = mxGetM(prhs[0]);
    size_t N = mxGetN(prhs[0]);
    double threshold = mxGetScalar(prhs[1]);

    plhs[0] = mxCreateCellMatrix(1, N);

    // Parallelize the outer loop across all available CPU cores
    #pragma omp parallel for
    for (size_t i = 0; i < N; ++i) {
        std::vector<double> forbidden;
        for (size_t j = 0; j < N; ++j) {
            if (i == j) continue;

            int K = 0;
            // The inner loop: Cache-friendly traversal
            for (size_t d = 0; d < D; ++d) {
                // if (basis[i * D + d] >= 1.0 && basis[j * D + d] >= 1.0) {
				if ((basis[i * D + d] + basis[j * D + d]) > 1.05) {
                    K++;
                }
            }

            if (K > threshold) {
                forbidden.push_back((double)j + 1.0);
            }
        }

        mxArray *cell_array = mxCreateDoubleMatrix(1, forbidden.size(), mxREAL);
        double *data = mxGetPr(cell_array);
        for (size_t k = 0; k < forbidden.size(); ++k) {
            data[k] = forbidden[k];
        }
        // Locking is not needed here as we write to specific indices of the cell array
        #pragma omp critical
        {
            mxSetCell(plhs[0], i, cell_array);
        }
    }
}