
#' Find Build-Time Package Dependencies
#'
#' Most R package dependencies are run-time dependencies: functions within
#' a package refer to functions or other objects within another package.
#' These references are resolved at runtime, and for evaluating the code
#' of a package (i.e. installing it), the dependencies are not actually
#' needed. This package tries to work out the build-time and run-time
#' dependencies of a package, by trying to evaluate the package code both
#' without and with each dependency.
#'
#' The current algorithms is this:
#' * If a dependency is linked to (i.e. its type is `LinkingTo`), this is
#'   a build-time dependency, and we install it.
#' * We try to evaluate the package code with only the `LinkingTo`
#'   dependencies available. This should already run without errors for most
#'   packages, and if it indeed does, then there are no additional
#'   dependencies.
#' * Otherwise we install all dependencies first, and then employ a
#'   "leave one out" strategy for the non `LinkingTo` packages: for each
#'   imported or depended package, we omit this single package and try to
#'   evaluate the package code.
#'
#' @param path Path to the package root.
#' @return Character vector, the names of the packages that are
#'   build dependencies.
#'
#' @importFrom rprojroot find_package_root_file
#' @importFrom desc desc_get_deps desc_get
#' @importFrom utils install.packages
#' @export

build_deps <- function(path = ".") {

  path <- normalizePath(find_package_root_file(path))
  package_name <- desc_get(path, keys = "Package")
  "!DEBUG package: `package_name`"

  ## Create a copy of the whole package, because we'll modify the
  ## DESCRIPTION file to load code with pkgload
  dir.create(tmp <- tempfile())
  on.exit(unlink(tmp, recursive = TRUE))
  "!DEBUG making a copy in '`tmp`'"
  file.copy(path, tmp, recursive = TRUE)
  pkgdir <- file.path(tmp, basename(path))

  ## All dependencies
  deps <- desc_get_deps(pkgdir)

  ## Drop base packages
  deps <- deps[ ! deps$package %in% base_packages(), ]

  ## LinkingTo is special, we don't need Suggests and Enhances,
  ## and can also drop Imports for LinkingTo
  deps <- deps[ deps$type != "Suggests", ]
  deps <- deps[ deps$type != "Enhances", ]
  linkingto <- deps[ deps$type == "LinkingTo", ]
  deps <- deps[ ! deps$package %in% linkingto$package, ]

  ## Use a temporary package library for the dependencies
  dir.create(libdir <- tempfile())
  "!DEBUG temporary package library: '`libdir`'"
  orig <- .libPaths()
  on.exit(.libPaths(orig))
  .libPaths(libdir)

  ## Install LinkingTo packages
  "!DEBUG install LinkingTo packages: `collapse(linkingto$package)`"
  if (length(linkingto$package)) install.packages(linkingto$package)

  ## Build dependencies found so far
  builddeps <- linkingto$package

  ## Try to load the package, in another session
  "!DEBUG try loading with LinkingTo only"
  if (try_load(pkgdir, libpath = .libPaths(), package_name)) {
    "!DEBUG loaded successfully"
    return(builddeps)
  }
  "!DEBUG loading failed"

  ## If failed, then install all dependencies
  "!DEBUG install all dependencies: `collapse(deps$package)`"
  install.packages(deps$package)

  ## Try to load now, this should succeed
  "!DEBUG try to load with all dependencies installed"
  if (! try_load(pkgdir, libpath = .libPaths(), package_name)) {
    stop("Cannot install package from ", sQuote(path))
  }

  ## Now try removing dependencies one by one, and see if it loads
  for (out in deps$package) {
    "!DEBUG try to load without `out`"
    if (!try_load_without(pkgdir, libpath = .libPaths(), package_name, out)) {
      "!DEBUG FAILED, `out` is a build dependency!"
      builddeps <- c(builddeps, out)
    }
  }

  builddeps
}
