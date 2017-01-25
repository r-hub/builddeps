


# builddeps

> Find Build-Time Package Dependencies

[![Linux Build Status](https://travis-ci.org/r-hub/builddeps.svg?branch=master)](https://travis-ci.org/r-hub/builddeps)
[![Windows Build status](https://ci.appveyor.com/api/projects/status/github/r-hub/builddeps?svg=true)](https://ci.appveyor.com/project/gaborcsardi/builddeps)
[![](http://www.r-pkg.org/badges/version/builddeps)](http://www.r-pkg.org/pkg/builddeps)
[![CRAN RStudio mirror downloads](http://cranlogs.r-pkg.org/badges/builddeps)](http://www.r-pkg.org/pkg/builddeps)
[![Coverage Status](https://img.shields.io/codecov/c/github/r-hub/builddeps/master.svg)](https://codecov.io/github/r-hub/builddeps?branch=master)

Most R package dependencies are run-time dependencies: functions within a
package refer to functions or other objects within another package. These
references are resolved at runtime, and for evaluating the code of a
package (i.e. installing it), the dependencies are not actually needed.
This package tries to work out the build-time and run-time dependencies of
a package, by trying to evaluate the package code both without and with
each dependency.

## Installation


```r
source("https://install-github.me/r-hub/builddeps")
```

## Usage


```r
library(builddeps)
build_deps(<package-tree>)
```

## Internals

Most R package dependencies are run-time dependencies: functions within
a package refer to functions or other objects within another package.
These references are resolved at runtime, and for evaluating the code
of a package (i.e. installing it), the dependencies are not actually
needed. This package tries to work out the build-time and run-time
dependencies of a package, by trying to evaluate the package code both
without and with each dependency.

The current algorithms is this:

1. If a dependency is linked to (i.e. its type is `LinkingTo`), this is
   a build-time dependency, and we install it.
2. We try to evaluate the package code with only the `LinkingTo`
   dependencies available. This should already run without errors for
   most packages, and if it indeed does, then there are no additional
   build dependencies.
3. Otherwise we install all dependencies and check that the package
   installs with them. If it does not then it is not possible to work
   out the build dependencies, so we give up here.
4. Otherwise, we *try* the dependencies one by one. We remove it, and
   try to install the package without it. If it installs, then it is not
   a build dependency. If it does not install, then it is a build
   dependency.

It is important that in step 4., the packages are considered in an
appropriate order. E.g. if `pkg -> A -> B` and also `pkg -> B` holds,
then we cannot try to omit package `B` first, because even if it is not
a build dependency, it is needed for package `A`, so the installation
of `pkg` will fail. So we create the dependency graph of all recursive
dependencies of the package, and try omitting the (directly dependent)
packages according to the topological ordering.

E.g. for the example above, we test package `A` first. (Assuming there
are no other direct dependencies depending on `A`, directly or
indirectly.)

* If `A` is a build dependency, then we always keep it installed in the
  following package tests.
* If `A` is not a build dependency, then we can remove it from the
  testing procedure for good, as no other packages in the dependency
  tree depend on it directly or indirectly.

## License

MIT © R Consortium
