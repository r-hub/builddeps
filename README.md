


# builddeps

> Find Build-Time Package Dependencies

[![Linux Build Status](https://travis-ci.org/r-hub/builddeps.svg?branch=master)](https://travis-ci.org/r-hub/builddeps)
[![Windows Build status](https://ci.appveyor.com/api/projects/status/github/r-hub/builddeps?svg=true)](https://ci.appveyor.com/project/gaborcsardi/builddeps)
[![](http://www.r-pkg.org/badges/version/builddeps)](http://www.r-pkg.org/pkg/builddeps)
[![CRAN RStudio mirror downloads](http://cranlogs.r-pkg.org/badges/builddeps)](http://www.r-pkg.org/pkg/builddeps)

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
```

## License

MIT © R Consortium
