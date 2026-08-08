#include "mex.h"
#include <vector>
#include <omp.h>

// mex -setup C++
// mex -v getForbiddenIndxs3_mex_o1.cpp
// mex -v COMPFLAGS="$COMPFLAGS /openmp" getForbiddenIndxs3_mex_o1.cpp
// mex COMPFLAGS="$COMPFLAGS /openmp" getForbiddenIndxs3_mex_o1.cpp

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    double *tileIDs = mxGetPr(prhs[0]);
    double *basis = mxGetPr(prhs[1]);
    double threshold = mxGetScalar(prhs[2]);
    
    size_t D = mxGetM(prhs[1]); // Vector dimension
    size_t N = mxGetN(prhs[1]); // Number of variables
    double tol = 1e-2;

    plhs[0] = mxCreateCellMatrix(1, N);

    #pragma omp parallel for
    for (size_t s = 0; s < N; ++s) {
        std::vector<double> forbidden;
        double ks = tileIDs[s];

        for (size_t o = s + 1; o < N; ++o) {
            double ko = tileIDs[o];
            
            if (ko != ks) {
                int count_intersected = 0;
                // Intersection logic: (vec1 + vec2) > (1.0 + tol)
                for (size_t d = 0; d < D; ++d) {
                    if ((basis[s * D + d] + basis[o * D + d]) > (1.0 + tol)) {
                        count_intersected++;
                    }
                }

                if (count_intersected > threshold) {
                    forbidden.push_back((double)(o + 1)); // 1-based index
                }
            }
        }

        mxArray *cell_array = mxCreateDoubleMatrix(1, forbidden.size(), mxREAL);
        double *data = mxGetPr(cell_array);
        for (size_t k = 0; k < forbidden.size(); ++k) {
            data[k] = forbidden[k];
        }
        
        #pragma omp critical
        {
            mxSetCell(plhs[0], s, cell_array);
        }
    }
}