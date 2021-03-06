% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in RtmpOWZhCV/file24f87761a0f2
\name{reshape_comparison_results}
\alias{reshape_comparison_results}
\title{Convert comparison results to a more general format}
\usage{
reshape_comparison_results(oneComparisonResult, includeVars = TRUE,
  includeEfficiency = TRUE, includeTiming = TRUE)
}
\arguments{
\item{oneComparisonResult}{An object returned by \code{\link{compareMCMCs}} (or \code{\link{combine_MCMC_comparison_results}} or \code{\link{rename_MCMC_comparison_method}}).}

\item{includeVars}{(default TRUE): whether to include the summary elements for each variable}

\item{includeEfficiency}{(default TRUE): whether to include the efficiency for each variable}

\item{includeTiming}{(default TRUE): whether to include the timing for each variable (which is the same for all variables from the same MCMC method)}
}
\value{
A data frame with the content from oneComparisonResult reshaped
}
\description{
Useful for making new kinds of figures or other needs
}
\details{
This is used internally by \code{\link{make_MCMC_comparison_pages}} but could also be useful to users who want to do their own thing with results from \code{\link{compareMCMCs}}.
}

