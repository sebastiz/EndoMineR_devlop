% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Basic_CleanUp.R
\name{spellCheck}
\alias{spellCheck}
\title{Find and Replace function}
\usage{
spellCheck(pattern, replacement, x, fixed = FALSE, ...)
}
\arguments{
\item{pattern}{the pattern to look for}

\item{replacement}{the pattern replaceme with}

\item{x}{the target string}
}
\value{
This returns a character vector
}
\description{
This is a helper function for finding and replacing from dictionaries like the event list
It uses fuzzy find and replace to account for spelling errors
}
\examples{
L <- tolower(stringr::str_split(HistolType(),"\\\\|"))
inputText<-TheOGDReportFinal$OGDReportWhole
inputText<-Reduce(function(x, nm) spellCheck(nm, L[[nm]], x), init = inputText, names(L))

}
\keyword{Find}
\keyword{and}
\keyword{replace}
