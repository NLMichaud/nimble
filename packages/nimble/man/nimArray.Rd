% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in RtmpOWZhCV/file24f870deea46
\name{nimArray}
\alias{array}
\alias{nimArray}
\title{Creates a array object of arbitrary dimension for use in NIMBLE DSL functions}
\usage{
nimArray(value = 0, dim = c(1, 1), init = TRUE, type = "double")
}
\arguments{
\item{value}{the initial value for each element of the array (default = 0)}

\item{dim}{a vector specifying the dimensionality and sizes of the array, provided as c(size1, ...) (default = c(1, 1))}

\item{init}{logical, whether to initialize elements of the matrix (default = TRUE)}

\item{type}{character representing the data type, i.e. 'double' or 'integer' (default = 'double')}
}
\description{
In a \code{nimbleFunction}, \code{array} is identical to \code{nimArray}
}
\details{
See the User Manual for usage examples.

When used in a \code{nimbleFunction} (in \code{run} or other member function), \code{array} is a synonym for \code{nimArray}.  When used with only the first two arguments, this behaves similarly to R's \code{array} function.  NIMBLE provides additional arguments to control the initialization value, whether or not initialization will occur, and the type of scalar elements.  Using \code{init=FALSE} when initialization is not necessary can make compiled nimbleFunctions a bit faster.
}
\author{
Daniel Turek
}
\seealso{
\code{\link{numeric}} \code{\link{integer}} \code{\link{matrix}}
}

