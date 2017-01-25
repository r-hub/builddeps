
#' @importFrom utils installed.packages

base_packages <- function() {
  unname(installed.packages(priority="base")[, "Package"])
}

random_name <- function() {
  paste(
    sample(c(letters, LETTERS), 8, replace = TRUE),
    collapse = ""
  )
}

collapse <- function(x) {
  paste(x, collapse = ", ")
}

file_rename_ex <- function(from, to) {
  ex <- file.exists(from)
  if (any(ex)) file.rename(from[ex], to[ex])
}

drop_names <- function(list, drop) {
  list[! names(list) %in% drop]
}
