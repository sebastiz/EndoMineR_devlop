% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Graphics.R
\name{EndoDataVizNum_y}
\alias{EndoDataVizNum_y}
\title{Create non-Numeric x versus y}
\usage{
EndoDataVizNum_y(dataframe, xdata, Prop)
}
\arguments{
\item{dataframe}{dataframe}

\item{xdata}{The category column}

\item{Prop}{The proportion column}
}
\value{
Myplot the EDA final plot

Myplot
}
\description{
This allows us to look at the overall flow from one
type of procedure to another using circos plots.
}
\examples{
# This function plot numeric y vs non-numeric x
MyendoNew<-cbind(EndoscMeds(Myendo$Medications),Myendo)
kk<-MetricByEndoscopist(MyendoNew,'Endoscopist','Fent')
EndoDataVizNum_y(kk,'Endoscopist','avg')
}
\keyword{Circos}
