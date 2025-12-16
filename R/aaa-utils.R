# aaa-utils.R - Internal utilities (loaded first alphabetically)
#
# Contains operator definitions and utilities needed by other package files.

#' Null coalescing operator
#'
#' Returns lhs if not NULL, otherwise rhs. Equivalent to rlang's %||%.
#'
#' @param lhs Left-hand side value
#' @param rhs Right-hand side (default) value
#' @return lhs if not NULL, otherwise rhs
#' @keywords internal
#' @name null-coalesce
`%||%` <- function(lhs, rhs) {
  if (is.null(lhs)) rhs else lhs
}
