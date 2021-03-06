% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/cfData-plotMethods.R
\name{plot,cfTemp,missing-method}
\alias{plot,cfTemp,missing-method}
\alias{plot.cfTemp}
\title{Plot Temperature Range}
\usage{
\S4method{plot}{cfTemp,missing}(
  x,
  y,
  ggtheme = c("grey", "gray", "bw", "linedraw", "light", "minimal", "classic"),
  scales = c("fixed", "free_x", "free_y", "free"),
  n_col = 1,
  ...
)
}
\arguments{
\item{x}{a cfTemp object.}

\item{y}{missing.}

\item{ggtheme}{character string (partially) matching the
\code{\link[ggplot2]{ggtheme}} to be used for plotting, see
'Theme Selection' below.}

\item{scales}{character string partially matching the \code{scales} argument
in the \code{link[ggplot2]{facet_wrap}} function.}

\item{n_col}{the number of columns of plots (default 1).}

\item{...}{further arguments passed to \code{\link[ggplot2]{theme}}.}
}
\description{
Plot minimum and maximum temperature data for a given period (degrees
celsius) through time, for each chosen CliFlo station.
}
\details{
This plotting method shows the temperature extremes as a grey region on the
plot, with a black line indicating the average temperature (if available).
}
\examples{
\dontrun{
# Retrieve public hourly minimum and maximum temperature data for the last
week at Reefton Ews station

# Subtract 7 days from today's date to get the start date
last_week = paste(as.character(Sys.Date() - 7), 0)

reefton_temp = cf_query(cf_user(), cf_datatype(4, 2, 2), cf_station(),
                        start_date = last_week)

class(reefton_temp) # cfTemp object

# Plot the temperature data using the defaults
plot(reefton_temp)

# Enlarge the text and add the observations as points
library(ggplot2) # for element_text() and geom_point()
plot(reefton_temp, ggtheme = "bw", text = element_text(size = 16)) +
  geom_point(size = 3, shape = 1)

# Save the plot as a png to the current working directory
library(ggplot2) # for ggsave()
ggsave("my_temperature_plot.png")
}
}
\seealso{
\code{\link{plot,cfDataList,missing-method}} for general
  information on default plotting of \code{cfData} and \code{cfDataList}
  objects, and the links within. See \code{\link{cf_query}} for creating
  \code{cfTemp} objects.

  Refer to \code{\link[ggplot2]{theme}} for more possible arguments to pass
  to these methods.
}
