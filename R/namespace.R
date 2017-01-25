
#' Remove some imports from the namespace
#'
#' @param ns The `namespace` object, as read by the `parseNamespaceFile`
#'   function.
#' @param without Character vector of package names to omit from the
#'   imports.
#' @return A `namespace` object, after the `without` packages were
#'   removed from the imports.
#'
#' @keywords internal

filter_namespace <- function(ns, without) {

  filt <- function(x) ! x[[1]] %in% without

  ns$imports <- Filter(filt, ns$imports)
  ns$importClasses <- Filter(filt, ns$importClasses)
  ns$importMethods <- Filter(filt, ns$importMethods)
  ns$dynlibs <- setdiff(ns$dynlibs, without)
  ns$nativeRoutines <-
    ns$nativeRoutines[setdiff(names(ns$nativeRoutines), without)]

  ns
}

#' Write out a `NAMESPACE` file
#'
#' Note that this does **not** reproduce the original namespace,
#' e.g. R code for conditional imports is lost. For `builddeps` this is OK,
#' because we parse `NAMESPACE` and use the modified version on the
#' same system, so they should evaluate the same way.
#'
#' @param ns The `namespace` object, as read by the `parseNamespaceFile`
#'   function.
#' @param path Path to the namespace file.
#'
#' @keywords internal

write_namespace <- function(ns, path) {

  add <- function(..., nl = TRUE) {
    cat(
      paste0(..., collapse = ""),
      if (nl) "\n" else "",
      file = path,
      append = TRUE,
      sep = ""
    )
  }

  enq <- function(x, collapse = ", ") {
    if (length(x)) {
      paste0("\"", x, "\"", collapse = collapse)
    } else {
      ""
    }
  }

  omit_zchar <- function(x) {
    x[nzchar(x)]
  }

  pattern_str <- function(pat, name = "exportPattern") {
    ep <- parse(text = deparse(pat))[[1]]
    ep[[1]] <- as.symbol(name)
    format(ep)
  }

  cat("", file = path)

  ## imports
  lapply(ns$imports, function(x) {
    if (length(x) == 1) {
      add("import(\"", x, "\")")

    } else if (identical(names(x)[[2]], "except")) {
      add("import(\"", x[[1]], "\", except = c(", enq(x[[-1]]), "))")

    } else {
      add("importFrom(", enq(unlist(x)), ")")
    }
  })

  ## exports
  if (length(ns$exports)) add("export(", enq(ns$exports), ")")

  ## exportPatterns
  if (length(ns$exportPatterns)) {
    add(pattern_str(ns$exportPatterns))
  }

  ## importClasses
  lapply(ns$importClasses, function(x) {
    add("importClassesFrom(", enq(unlist(x)), ")")
  })

  ## importMethods
  lapply(ns$importMethods, function(x) {
    add("importMethodsFrom(", enq(unlist(x)), ")")
  })

  ## exportClasses
  if (length(ns$exportClasses)) {
    add("exportClasses(", enq(ns$exportClasses), ")")
  }

  ## exportMethods
  if (length(ns$exportMethods)) {
    add("exportMethods(", enq(ns$exportMethods), ")")
  }

  ## exportClassPatterns
  if (length(ns$exportClassPatterns)) {
    add(pattern_str(ns$exportClassPatterns, "exportClassPattern"))
 }

  ## dynlibs and nativeRoutines
  lapply(setdiff(ns$dynlibs, names(ns$nativeRoutines)), function(x) {
    add("useDynLib(", enq(x), ")")
  })
  lapply(names(ns$nativeRoutines), function(x) {
    xx <- ns$nativeRoutines[[x]]
    add("useDynlib(", enq(x), nl = FALSE)
    if (length(xx$symbolNames)) {
      add(
        ", ",
        paste0("\"", names(xx$symbolNames), "\" = \"",
               xx$symbolNames, "\"", collapse = ", "),
        nl = FALSE
      )
    }
    if (xx$useRegistration) add(", .registration = TRUE", nl = FALSE)
    if (length(omit_zchar(xx$registrationFixes))) {
      add(
        ", .fixes = ",
        deparse(omit_zchar(xx$registrationFixes)),
        nl = FALSE
      )
    }
    add(")")
  })

  ## S3methods
  if (length(ns$S3methods)) {
    apply(ns$S3methods, 1, function(x) add("S3method(", enq(na.omit(x)), ")"))
  }

  invisible()
}
