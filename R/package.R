
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
#' @docType package
#' @name builddeps
NULL

#' @importFrom rprojroot find_package_root_file
#' @importFrom desc desc_get_deps
#' @importFrom remotes install_version
#' @export

build_deps <- function(path = ".") {

  path <- normalizePath(find_package_root_file(path))

  ## Create a copy of the whole package, because we'll modify the
  ## DESCRIPTION file to load code with pkgload
  dir.create(tmp <- tempfile())
  on.exit(unlink(tmp, recursive = TRUE))
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
  orig <- .libPaths()
  on.exit(.libPaths(orig))
  .libPaths(libdir)

  ## Install LinkingTo packages
  if (length(linkingto$package)) lapply(linkingto$package, install_version)

  ## Build dependencies found so far
  builddeps <- linkingto$package

  ## Try to load the package, in another session
  if (try_load(pkgdir, libpath = .libPaths())) return(builddeps)

  ## If failed, then install all dependencies
  lapply(deps$package, install_version)

  ## Try to load now, this should succeed
  if (! try_load(pkgdir, libpath = .libPaths())) {
    stop("Cannot install package from ", sQuote(path))
  }

  ## Now try removing dependencies one by one, and see if it loads
  for (pkg in deps$package) {
    if (!try_load_without(pkgdir, libpath = .libPaths(), pkg)) {
      builddeps <- c(builddeps, pkg)
    }
  }

  builddeps
}
