
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

try_load <- function(path, libpath, pkg) {

  fun <- function(path, pkg) {
    dir.create(tmp <- tempfile())
    options(warn = 2)
    utils::install.packages(
      path,
      lib = tmp,
      repos = NULL,
      type = "source",
      INSTALL_opts = c("--no-test-load", "--no-byte-compile")
    )
  }

  outfile <- tempfile()
  errfile <- tempfile()

  res <- tryCatch(
    r_vanilla(
      fun,
      libpath = libpath,
      repos = getOption("repos"),
      args = list(path = path, pkg = pkg),
      stdout = outfile,
      stderr = errfile
    ),
    error = function(e) {
      "!DEBUG - ERROR --------\n"
      "!DEBUG `e$message`"
      "!DEBUG - STDOUT -------\n"
      "!DEBUG `paste(readLines(outfile), collapse = '\n')`"
      "!DEBUG - STDERR -------\n"
      "!DEBUG `paste(readLines(errfile), collapse = '\n')`"
      "!DEBUG ----------------\n"
      "failed"
    }
  )

  ! identical(res, "failed")
}

#' @importFrom desc description

try_load_without <- function(path, libpath, pkg, without) {

  ## This is to restore the original state
  desc <- description$new(path)
  on.exit(desc$write(), add = TRUE)

  ## This is the temporary DESCRIPTION, without 'without'
  desctmp <- description$new(path)
  desctmp$del_dep(without)$write()

  ## We also need to remove the package from the package library,
  ## temporaily, because the references to it might use :: or :::
  ## Instead of removing it, we just rename it. This works, unless
  ## the R process crashes, in which case whole process is done, anyway.
  pkgdir <- file.path(libpath[1], without)
  pkgdir_copy <- file.path(libpath[1], random_name())
  on.exit(file.rename(pkgdir_copy, pkgdir), add = TRUE)
  file.rename(pkgdir, pkgdir_copy)

  try_load(path, libpath, pkg)
}
