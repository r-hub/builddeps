
hard_dependencies <- c("Imports", "Depends", "LinkingTo")

#' Create a package dependency graph
#'
#' This only contains all recursive dependencies of the package under study,
#' since it might happen that a dependency depends on another dependency
#' indirectly, and we need to know about this.
#'
#' @param pkgfiles The names of the package files. We assume that all
#'   (non-base) recursive dependencies are included here.
#' @return The dependency graph, a named list, an out-adjacency list.
#'
#' @keywords internal

make_depgraph <- function(pkgfiles) {
  structure(
    lapply(pkgfiles, get_hard_dependencies),
    names = names(pkgfiles)
  )
}

#' @importFrom desc desc_get_deps

get_hard_dependencies <- function(desc) {
  deps <- desc_get_deps(desc)
  deps <- deps[ deps$type %in% hard_dependencies,, drop = FALSE ]
  setdiff(unique(deps$package), c(base_packages(), "R"))
}

get_linkingto_dependencies <- function(desc) {
  deps <- desc_get_deps(desc)
  deps$package[deps$type == "LinkingTo"]
}

#' Yield the next package to try from the depgraph
#'
#' @param graph The dependency graph.
#' @return Character scalar, the name of the next package to try.
#'
#' @keywords internal

next_pkg_from_depgraph <- function(graph) {
  setdiff(names(graph), unique(unlist(graph)))[1]
}

#' Remove a package (or more) from the dependency graph
#'
#' @param graph Dependency graph.
#' @param pkg Package(s) to remove.
#' @return The cleaned up dependency graph.
#'
#' @keywords internal

del_pkg_from_depgraph <- function(graph, pkg) {
  graph <- structure(lapply(graph, setdiff, pkg), names = names(graph))
  graph[ ! names(graph) %in% pkg ]
}
