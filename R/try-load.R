
#' Try loading a package from a directory
#'
#' It tries the loading in another R session.
#'
#' @param path Path to the package directory.
#' @param libpath The library path to set.
#' @return Flag (logical scalar), whether the package loading was
#'   successful or not.
#'
#' @importFrom callr r_vanilla
#' @keywords internal

try_load <- function(path, libpath) {

  res <- tryCatch(
    r_vanilla(
      function(path) pkgload::load_all(path, export_all = FALSE),
      libpath = libpath,
      repos = getOption("repos"),
      args = list(path = path)
    ),
    error = function(e) { print(e) ; "failed" }
  )

  ! identical(res, "failed")
}

#' @importFrom desc description

try_load_without <- function(path, libpath, without) {

  ## This is to restore the original state
  desc <- description$new(path)
  on.exit(desc$write())

  ## This is the temporary DESCRIPTION, without 'without'
  desctmp <- description$new(path)
  desctmp$del_dep(without)$write()

  try_load(path, libpath)
}
