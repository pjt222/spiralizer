// spiral_rcpp.cpp - High-performance spiral generation using Rcpp
//
// Provides C++ implementations of compute-intensive operations
// for significant speedup over pure R code.

#include <Rcpp.h>
#include <cmath>
using namespace Rcpp;

//' Generate Fermat Spiral Points (C++ Implementation)
//'
//' Fast C++ implementation of Fermat spiral point generation.
//' Uses vectorized operations and pre-allocation for optimal performance.
//'
//' @param angle_start Starting angle
//' @param angle_end Ending angle
//' @param num_points Number of points to generate
//' @return NumericMatrix with x,y coordinates
//' @export
// [[Rcpp::export]]
NumericMatrix generate_spiral_cpp(double angle_start, double angle_end, int num_points) {
  // Pre-allocate output matrix
  NumericMatrix points(num_points, 2);

  // Calculate step size

double step = (angle_end - angle_start) / (num_points - 1);

  // Generate points
  for (int i = 0; i < num_points; i++) {
    double theta = angle_start + i * step;
    double sqrt_theta = std::sqrt(theta);

    points(i, 0) = sqrt_theta * std::cos(theta);  // x
    points(i, 1) = sqrt_theta * std::sin(theta);  // y
  }

  // Set column names
  colnames(points) = CharacterVector::create("x", "y");

  return points;
}

//' Calculate Plot Limits (C++ Implementation)
//'
//' Efficiently calculates the maximum absolute coordinate from a matrix.
//'
//' @param vertices NumericMatrix of vertex coordinates
//' @param padding Padding factor (e.g., 1.1 for 10% padding)
//' @return NumericVector with c(-limit, limit)
//' @export
// [[Rcpp::export]]
NumericVector calculate_limits_cpp(NumericMatrix vertices, double padding = 1.1) {
  if (vertices.nrow() == 0) {
    return NumericVector::create(-10.0, 10.0);
  }

  double max_abs = 0.0;

  for (int i = 0; i < vertices.nrow(); i++) {
    double abs_x = std::abs(vertices(i, 0));
    double abs_y = std::abs(vertices(i, 1));

    if (abs_x > max_abs) max_abs = abs_x;
    if (abs_y > max_abs) max_abs = abs_y;
  }

  double limit = std::ceil(max_abs * padding);

  return NumericVector::create(-limit, limit);
}

//' Fast Bounded Cell Count
//'
//' Counts bounded cells by checking if all vertices are finite.
//' Much faster than R's Filter() for large cell counts.
//'
//' @param vertex_counts IntegerVector of vertex counts per cell
//' @param has_infinite LogicalVector indicating if cell has infinite vertices
//' @return Integer count of bounded cells
//' @export
// [[Rcpp::export]]
int count_bounded_cells_cpp(LogicalVector has_infinite) {
  int count = 0;

  for (int i = 0; i < has_infinite.size(); i++) {
    if (!has_infinite[i]) {
      count++;
    }
  }

  return count;
}
