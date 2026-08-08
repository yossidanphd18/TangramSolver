#include "mex.hpp"
#include "mexAdapter.hpp"
#include <vector>
#include <cmath>
#include <algorithm>

struct BBox {
    double xmin, xmax, ymin, ymax;
};

// Cross product helper to determine orientation
double ccw(double ax, double ay, double bx, double by, double cx, double cy) {
    return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
}

// Check if segment AB and segment CD cross each other strictly 
// (Returns false if they just touch, are collinear, or share an endpoint)
bool edges_cross_strictly(double ax, double ay, double bx, double by, 
                          double cx, double cy, double dx, double dy) {
    double cp1 = ccw(ax, ay, bx, by, cx, cy);
    double cp2 = ccw(ax, ay, bx, by, dx, dy);
    double cp3 = ccw(cx, cy, dx, dy, ax, ay);
    double cp4 = ccw(cx, cy, dx, dy, bx, by);
    
    // Strict crossing requires endpoints to be on strictly opposite sides
    if (((cp1 > 1e-4 && cp2 < -1e-4) || (cp1 < -1e-4 && cp2 > 1e-4)) &&
        ((cp3 > 1e-4 && cp4 < -1e-4) || (cp3 < -1e-4 && cp4 > 1e-4))) {
        return true;
    }
    return false;
}

// Ray-casting algorithm to see if a point is strictly inside a general polygon
bool point_strictly_in_polygon(double px, double py, const double* v, size_t n) {
    bool inside = false;
    for (size_t i = 0; i < n; ++i) {
        size_t j = (i + 1) % n;
        double xi = v[i], yi = v[i + n];
        double xj = v[j], yj = v[j + n];
        
        // Strict boundary checking: if point is on the horizontal edge, don't count as strictly inside
        if (std::abs(yi - py) < 1e-4 && std::abs(yj - py) < 1e-4) {
            if (px >= std::min(xi, xj) - 1e-4 && px <= std::max(xi, xj) + 1e-4) return false;
        }

        if (((yi > py) != (yj > py)) &&
            (px < (xj - xi) * (py - yi) / (yj - yi + 1e-9) + xi)) {
            inside = !inside;
        }
    }
    return inside;
}

// General Polygon Overlap Checker (Handles Convex & Concave seamlessly)
bool check_general_overlap(const double* v1, size_t n1, const double* v2, size_t n2) {
    // Condition 1: Check if any edge of Polygon 1 strictly cuts through an edge of Polygon 2
    for (size_t i = 0; i < n1; ++i) {
        size_t next1 = (i + 1) % n1;
        double a1x = v1[i], a1y = v1[i + n1];
        double b1x = v1[next1], b1y = v1[next1 + n1];
        
        for (size_t j = 0; j < n2; ++j) {
            size_t next2 = (j + 1) % n2;
            double a2x = v2[j], a2y = v2[j + n2];
            double b2x = v2[next2], b2y = v2[next2 + n2];
            
            if (edges_cross_strictly(a1x, a1y, b1x, b1y, a2x, a2y, b2x, b2y)) {
                return true; 
            }
        }
    }
    
    // Condition 2: If no edges cross, one polygon might be completely nested inside the other.
    // Check if the center/representative interior point of Polygon 1 is inside Polygon 2
    double avg1_x = 0, avg1_y = 0;
    for (size_t i = 0; i < n1; ++i) {
        avg1_x += v1[i]; avg1_y += v1[i + n1];
    }
    if (point_strictly_in_polygon(avg1_x / n1, avg1_y / n1, v2, n2)) return true;
    
    double avg2_x = 0, avg2_y = 0;
    for (size_t j = 0; j < n2; ++j) {
        avg2_x += v2[j]; avg2_y += v2[j + n2];
    }
    if (point_strictly_in_polygon(avg2_x / n2, avg2_y / n2, v1, n1)) return true;

    return false;
}

class MexFunction : public matlab::mex::Function {
public:
    void operator()(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        matlab::data::ArrayFactory factory;

        const matlab::data::TypedArray<double> shape_ids = std::move(inputs[0]);
        const matlab::data::CellArray vertices_cell = std::move(inputs[1]);
        
        size_t N = shape_ids.getNumberOfElements();
        
        std::vector<BBox> bboxes(N);
        std::vector<const double*> vertices_ptr(N);
        std::vector<size_t> num_vertices(N);
        
        for (size_t i = 0; i < N; ++i) {
            matlab::data::TypedArray<double> v = vertices_cell[i];
            size_t n = v.getDimensions()[0]; 
            num_vertices[i] = n;
            
            const double* ptr = &(*v.cbegin());
            vertices_ptr[i] = ptr;
            
            double xmin = ptr[0], xmax = ptr[0];
            double ymin = ptr[n], ymax = ptr[n];
            for(size_t k = 1; k < n; ++k) {
                xmin = std::min(xmin, ptr[k]); xmax = std::max(xmax, ptr[k]);
                ymin = std::min(ymin, ptr[n + k]); ymax = std::max(ymax, ptr[n + k]);
            }
            bboxes[i] = {xmin, xmax, ymin, ymax};
        }

        matlab::data::CellArray forbidden_cells = factory.createCellArray({N, 1});
        size_t total_disqualified = 0;

        for (size_t ns = 0; ns < N; ++ns) {
            double s_xmin = bboxes[ns].xmin, s_xmax = bboxes[ns].xmax;
            double s_ymin = bboxes[ns].ymin, s_ymax = bboxes[ns].ymax;
            double ks = shape_ids[ns];
            
            std::vector<double> current_forbidden;
            
            for (size_t n = ns + 1; n < N; ++n) {
                if (shape_ids[n] == ks) continue; 
                
                if (s_xmax < bboxes[n].xmin || s_xmin > bboxes[n].xmax ||
                    s_ymax < bboxes[n].ymin || s_ymin > bboxes[n].ymax) {
                    continue; 
                }
                
                if (check_general_overlap(vertices_ptr[ns], num_vertices[ns], vertices_ptr[n], num_vertices[n])) {
                    current_forbidden.push_back(static_cast<double>(n + 1)); 
                }
            }
            
            total_disqualified += current_forbidden.size();
            
            if (!current_forbidden.empty()) {
                forbidden_cells[ns] = factory.createArray({1, current_forbidden.size()}, current_forbidden.begin(), current_forbidden.end());
            } else {
                forbidden_cells[ns] = factory.createArray<double>({1, 0});
            }
        }

        outputs[0] = forbidden_cells;
        outputs[1] = factory.createScalar(static_cast<double>(total_disqualified));
    }
};