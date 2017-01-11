
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
