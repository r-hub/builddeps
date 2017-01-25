
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
#' 1. If a dependency is linked to (i.e. its type is `LinkingTo`), this is
#'    a build-time dependency, and we install it.
#' 2. We try to evaluate the package code with only the `LinkingTo`
#'    dependencies available. This should already run without errors for
#'    most packages, and if it indeed does, then there are no additional
#'    build dependencies.
#' 3. Otherwise we install all dependencies and check that the package
#'    installs with them. If it does not then it is not possible to work
#'    out the build dependencies, so we give up here.
#' 4. Otherwise, we *try* the dependencies one by one. We remove it, and
#'    try to install the package without it. If it installs, then it is not
#'    a build dependency. If it does not install, then it is a build
#'    dependency.
#'
#' It is important that in step 4., the packages are considered in an
#' appropriate order. E.g. if `pkg -> A -> B` and also `pkg -> B` holds,
#' then we cannot try to omit package `B` first, because even if it is not
#' a build dependency, it is needed for package `A`, so the installation
#' of `pkg` will fail. So we create the dependency graph of all recursive
#' dependencies of the package, and try omitting the (directly dependent)
#' packages according to the topological ordering.
#'
#' E.g. for the example above, we test package `A` first. (Assuming there
#' are no other direct dependencies depending on `A`, directly or
#' indirectly.)
#' * If `A` is a build dependency, then we always keep it installed in the
#'   following package tests.
#' * If `A` is not a build dependency, then we can remove it from the
#'   testing procedure for good, as no other packages in the dependency
#'   tree depend on it directly or indirectly.
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
  ## DESCRIPTION file to install the package
  dir.create(tmp <- tempfile())
  on.exit(unlink(tmp, recursive = TRUE))
  "!DEBUG making a copy in '`tmp`'"
  file.copy(path, tmp, recursive = TRUE)
  pkgdir <- file.path(tmp, basename(path))

  ## All dependencies, and linkingto separately
  deps <- get_hard_dependencies(pkgdir)
  linkingto <- get_linkingto_dependencies(pkgdir)

  ## Use a temporary package library for the dependencies
  dir.create(libdir <- tempfile())
  "!DEBUG temporary package library: '`libdir`'"
  orig <- .libPaths()
  on.exit(.libPaths(orig))
  .libPaths(libdir)

  ## Install LinkingTo packages
  "!DEBUG install LinkingTo packages: `collapse(linkingto)`"
  if (length(linkingto)) install.packages(linkingto)

  ## This is what we know at the start
  positive <- linkingto
  negative <- character()
  unknown <- setdiff(deps, positive)

  ## Try to load the package, in another session, with LinkingTo only
  "!DEBUG try loading with LinkingTo only"
  if (try_load_without(
      pkgdir,
      libpath = .libPaths(),
      pkg = package_name,
      without = unknown)) {
    "!DEBUG loaded successfully"
    return(positive)
  }
  "!DEBUG loading failed"

  ## If failed, then install all dependencies
  "!DEBUG install all dependencies: `collapse(deps)`"
  dir.create(cache_dir <- tempfile())
  install.packages(deps, destdir = cache_dir)

  ## Try to load now, this should succeed
  "!DEBUG try to load with all dependencies installed"
  if (! try_load(pkgdir, libpath = .libPaths(), package_name)) {
    stop("Cannot install package from ", sQuote(path))
  }

  ## We need to query all dependencies of the downloaded packages,
  ## and consider them in topological order.
  pkg_files <- list.files(cache_dir, full.names = TRUE)
  names(pkg_files) <- sub("_.*$", "", basename(pkg_files))

  depgraph <- make_depgraph(pkg_files)
  depgraph <- del_pkg_from_depgraph(depgraph, positive)

  while (length(unknown)) {
    candidate <- next_pkg_from_depgraph(depgraph)
    if (candidate %in% unknown) {
      "!DEBUG try to load without `candidate`"
      if (!try_load_without(pkgdir, libpath = .libPaths(), package_name,
                            c(negative, candidate))) {
        "!DEBUG FAILED, `candidate` is a build dependency!"
        positive<- c(positive, candidate)
      } else {
        "!DEBUG SUCCESS, `candidate` is NOT a build dependency!"
        negative <- c(negative, candidate)
      }
    }
    unknown <- setdiff(unknown, candidate)
    depgraph <- del_pkg_from_depgraph(depgraph, candidate)
  }

  positive
}
