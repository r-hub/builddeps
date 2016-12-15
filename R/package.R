
#' Find Build-Time Package Dependencies
#'
#' Most R package dependencies are run-time dependencies: functions within a
  package refer to functions or other objects within another package. These
  references are resolved at runtime, and for evaluating the code of a package
  (i.e. installing it), the dependencies are not actually needed. This package
  tries to work out the build-time and run-time dependencies of a package, by
  trying to evaluate the package code both without and with each dependency.
#'
#' @docType package
#' @name builddeps
NULL
