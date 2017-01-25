
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

  ## Make sure that the files exist
  cat("", file = outfile <- tempfile())
  cat("", file = errfile <- tempfile())

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

  ## Easy case
  if (!length(without)) return(try_load(path, libpath, pkg))

  ## Temporary DESCRIPTION, without the `without` package
  desc <- description$new(path)
  on.exit(desc$write(), add = TRUE)
  desctmp <- description$new(path)
  for (p in without) desctmp$del_dep(p)
  desctmp$write()

  ## Temporary NAMESPACE, without the `without` package
  file.copy(ns_file <- file.path(path, "NAMESPACE"), ns_tmp <- tempfile())
  on.exit(file.copy(ns_tmp, ns_file, overwrite = TRUE), add = TRUE)
  ns <- parseNamespaceFile(
    basename(dirname(ns_file)),
    dirname(dirname(ns_file))
  )
  write_namespace(filter_namespace(ns, without), ns_file)

  ## We also need to remove the packages from the package library,
  ## temporaily, because the references to them might use :: or :::
  ## Instead of removing it, we just rename it. This works, unless
  ## the R process crashes, in which case whole process is done, anyway.
  pkgdir <- file.path(libpath[1], without)
  pkgdir_copy <- file.path(
    libpath[1],
    replicate(length(without), random_name())
  )
  on.exit(file_rename_ex(pkgdir_copy, pkgdir), add = TRUE)
  file_rename_ex(pkgdir, pkgdir_copy)

  try_load(path, libpath, pkg)
}
