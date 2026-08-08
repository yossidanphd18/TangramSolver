#include "mex.h"
#include <vector>
#include <omp.h>
#include <cmath>
#include "clipper2/clipper.h"

// mex -setup C++

// mex CXXFLAGS="$CXXFLAGS -std=c++17" ...
//    -I'C:\Users\User\_REPOS_2\Clipper2\CPP\Clipper2Lib\include' ...
//    'check_intersection_mex_o1.cpp' ...
//    'C:\Users\User\_REPOS_2\Clipper2\CPP\Clipper2Lib/src/clipper.engine.cpp' ...
//    'C:\Users\User\_REPOS_2\Clipper2\CPP\Clipper2Lib/src/clipper.offset.cpp' ...
//    'C:\Users\User\_REPOS_2\Clipper2\CPP\Clipper2Lib/src/clipper.rectclip.cpp'
	
using namespace Clipper2Lib;

// Helper to convert MATLAB double matrix (N-by-2) to Clipper2 Path64
Path64 matrixToPath(const mxArray* mx_array, double scale) {
    size_t nrows = mxGetM(mx_array);
    double* data = mxGetPr(mx_array);
    Path64 path;
    path.reserve(nrows);
    for (size_t i = 0; i < nrows; ++i) {
        int64_t x = static_cast<int64_t>(std::round(data[i] * scale));
        int64_t y = static_cast<int64_t>(std::round(data[nrows + i] * scale));
        path.push_back(Point64(x, y));
    }
    return path;
}

void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[]) {
    if (nrhs < 3) {
        mexErrMsgIdAndTxt("MyToolbox:check_intersection_mex:nrhs", "Three inputs required: P1, P2, areaMinPercentage.");
    }

    // Input parsing
    const mxArray* mxP1 = prhs[0];
    const mxArray* mxP2 = prhs[1];
    double areaMinPercentage = mxGetScalar(prhs[2]);

    // Scaling factor to preserve decimal precision using 64-bit integers
    double scale = 1000.0; 
    double scaleSq = scale * scale;

    Path64 poly1_path = matrixToPath(mxP1, scale);
    Path64 poly2_path = matrixToPath(mxP2, scale);

    Paths64 sub, clip;
    sub.push_back(poly1_path);
    clip.push_back(poly2_path);

    // 1. Calculate individual areas (adjusted back for scale)
    double area1 = std::abs(Area(poly1_path)) / scaleSq;
    double area2 = std::abs(Area(poly2_path)) / scaleSq;
    double areaThreshold = areaMinPercentage * std::min(area1, area2);

    // 2. Perform Intersection using Clipper2
    Paths64 solution = Intersect(sub, clip, FillRule::NonZero);

    // 3. Calculate intersection area
    double overlapArea = 0.0;
    for (const auto& path : solution) {
        overlapArea += std::abs(Area(path));
    }
    overlapArea /= scaleSq;

    // 4. Compare and return boolean
    bool is_intersecting = (overlapArea > areaThreshold);

    plhs[0] = mxCreateLogicalScalar(is_intersecting);
}