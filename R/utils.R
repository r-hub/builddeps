
base_packages <- function() {
  unname(installed.packages(priority="base")[, "Package"])
}
