#' @include cfDataList.R
NULL

# Store the Last Clifro Query
set_history = function(value) cf_parallel[["last_cf_query"]] = value

#' Retrieve Last Query Result from CliFlo
#'
#' Retrieve the last query submitted to CliFlo instead of querying the database
#' again and losing subscription rows.
#'
#' This function is a back up for when the clifro query has been submitted and
#' the data returned but has not been assigned, or inadvertently deleted. This
#' saves the user resubmitting queries and using more rows from their
#' subscription than needed.
#'
#' @note Only the data from the last query is saved in \code{clifro}.
#'
#' @examples
#' \dontrun{
#' # Query CliFlo for wind at Reefton Ews
#' cf_query(cf_user(), cf_datatype(2, 1, 1, 1), cf_station(), "2012-01-01 00")
#'
#' # Oops! Forgot to assign it to a variable...
#' reefton.wind = cf_last_query()
#' reefton.wind
#' }
#' @export
cf_last_query = function() cf_parallel[["last_cf_query"]]

#  ------------------------------------------------------------------------

#' Retrieve Data from the National Climate Database
#'
#' Query the National Climate Database via CliFlo based on the \pkg{clifro} user
#' and selected datatypes, stations and dates.
#'
#' The \code{cf_query} function is used to combine the \pkg{clifro} user
#' (\code{\link{cfUser}}), along with the desired datatypes
#' (\code{\link{cfDatatype}}) and stations (\code{\link{cfStation}}). The query
#' is 'built up' using these objects, along with the necessary dates. The
#' function then uses all these data to query the National Climate Database via
#' the CliFlo web portal and returns one of the many \code{cfData}
#' objects if one dataframe is returned, or a \code{cfDataList} object if
#' there is more than one dataframe returned from CliFlo. If a \code{cfDataList}
#' is returned, each element in the list is a subclass of the \code{cfData}
#' class, see the 'cfData Subclasses' section.
#'
#' @param user a \code{\link{cfUser}} object.
#' @param datatype a \code{\link{cfDatatype}} object containing the datatypes to
#'                 be retrieved.
#' @param station a \code{\link{cfStation}} object containing the stations where
#'                the datatypes will be retrieved from.
#' @param start_date a character, Date or POSIXt object indicating the start
#'                   date. If a character string is supplied the date format
#'                   should be in the form \code{yyyy-mm-dd-hh} unless
#'                   \code{date_format} is specified.
#' @param end_date same as \code{start_date}. Defaults to
#'                 \code{\link[lubridate]{now}}.
#' @param date_format a character string matching one of \code{"ymd_h"},
#'                    \code{"mdy_h"}, \code{"ydm_h"} or \code{"dmy_h"}
#'                    representing the \code{\link[lubridate]{lubridate-package}}
#'                    date parsing function.
#' @param tz the timezone for which the start and end dates refer to. Conversion
#'           to Pacific/Auckland time is done automatically through the
#'           \code{\link[lubridate]{with_tz}} function. Defaults to
#'           "Pacific/Auckland".
#' @param output_tz the timezone of the output. This can be one of either "local",
#'                  "UTC", or "NZST".
#' @param quiet logical. When \code{TRUE} the function evaluates without
#'              displaying customary messages. Messages from CliFlo are still
#'              displayed.
#'
#' @section CfData Subclasses:
#'
#' There are 8 \code{cfData} subclasses that are returned from \code{cf_query}
#' depending on the datatype requested. Each of these subclasses have default
#' \code{plot} methods for usability and efficiency in exploring and plotting
#' \pkg{clifro} data.
#'
#' The following table summarises these subclasses and how they are created, see
#' also the examples on how to automatically create some of these subclasses.
#'
#' \tabular{ll}{
#' \strong{Subclass} \tab \strong{CliFlo Datatype}\cr
#' cfWind \tab Any 'Wind' data \cr
#' cfRain \tab Any 'Precipitation' data \cr
#' cfScreen Obs \tab 'Temperature and Humidity' data measured in a standard screen \cr
#' cfTemp \tab Maximum and minimum 'Temperature and Humidity' data \cr
#' cfEarthTemp \tab 'Temperature and Humidity' data at a given depth \cr
#' cfSunshine \tab Any 'Sunshine & Radiation' data \cr
#' cfPressure \tab Any 'Pressure' data \cr
#' cfOther \tab Any other CliFlo 'Daily and Hourly Observations' \cr
#' }
#'
#' @importFrom lubridate with_tz force_tz ymd_h mdy_h ydm_h dmy_h is.POSIXt year
#' month day hour
#' @importFrom stringr str_replace
#' @importFrom utils read.table head tail
#' @importFrom httr POST stop_for_status content
#' @return a \code{cfData} or \code{cfDataList} object.
#' @seealso \code{\link{cf_user}}, \code{\link{cf_datatype}} and
#'   \code{\link{cf_station}} for creating the objects needed for a query. See
#'   \code{\link{plot,cfDataList,missing-method}} for general information on
#'   default plotting of \code{cfData} and \code{cfDataList} objects, and the
#'   links within.
#' @examples
#' \dontrun{
#' # Retrieve daily rain data from Reefton Ews
#' daily.rain = cf_query(cf_user("public"), cf_datatype(3, 1, 1),
#'                       cf_station(), "2012-01-01 00")
#' daily.rain
#'
#' # returns a cfData object as there is only one datatype
#' class(daily.rain) # 'cfRain' object - inherits 'cfData'
#'
#' # Look up the help page for cfRain plot methods
#' ?plot.cfRain
#'
#' # Retrieve daily rain and wind data from Reefton Ews
#'
#' daily.dts = cf_query(cf_user("public"),
#'                      cf_datatype(c(2, 3), c(1, 1), list(4, 1), c(1, NA)),
#'                      cf_station(), "2012-01-01 00", "2013-01-01 00")
#' daily.dts
#'
#' # returns a cfDataList object as there is more than one datatype. Each
#' # element of the cfDataList is an object inheriting from the cfData class.
#' class(daily.dts)     # cfDataList
#' class(daily.dts[1])  # cfRain
#' class(daily.dts[2])  # cfWind
#'
#' # Create a cfSunshine object (inherits cfData)
#' # Retrieve daily global radiation data at Reefton Ews
#' rad.data = cf_query(cf_user(), cf_datatype(5,2,1), cf_station(),
#'                     "2012-01-01 00")
#' rad.data
#'
#' # The cf_query function automatically creates the appropriate cfData subclass
#' class(rad.data)
#'
#' # The advantage of having these subclasses is that it makes plotting very easy
#' plot(rad.data)
#' plot(daily.rain)
#' plot(daily.rain, include_runoff = FALSE)
#' plot(daily.dts)
#' plot(daily.dts, 2)
#' }
#' @export
cf_query = function(user, datatype, station, start_date, end_date = now(tz),
                    date_format = "ymd_h",
                    tz = "Pacific/Auckland", output_tz = c("local", "NZST", "UTC"), 
                    quiet = FALSE){

  if (!is(user, "cfUser"))
    stop("user must be a cfUser")
  if(!is(datatype, "cfDatatype"))
    stop("datatype must be a cfDatatype")
  if(!is(station, "cfStation"))
    stop("station must be a cfStation")

  if (user@username == "public" && is.na(match(3925, station@.Data[[3]])))
    stop("public users can only access data from Reefton EWS (3925)")

  date_format = match.arg(date_format, c("ymd_h", "mdy_h", "ydm_h", "dmy_h"))
  if (is.character(start_date)){
    start_date = eval(call(date_format, start_date, quiet = TRUE))
    if (is.na(start_date))
      stop("start date was not parsed with ", date_format)
  }
  if (is.character(end_date)){
    end_date = eval(call(date_format, end_date, quiet = TRUE))
    if (is.na(end_date))
      stop("end date was not parsed with ", date_format)
  }

  if (!(is.POSIXt(start_date) || is.POSIXt(end_date)))
    stop("start and end dates must be either character or POSIXt objects")
  
  # Force the timezones to match the 'tz' argument.
  start_date = force_tz(start_date, tz)
  end_date = force_tz(end_date, tz)
  
  output_tz = match.arg(output_tz)
  
  # Create local (NZ local timezone) start and end dates
  start_date = with_tz(start_date, "Pacific/Auckland")
  end_date = with_tz(end_date, "Pacific/Auckland")

  if (user@username != "public") {
    cf_login(user)
    on.exit(cf_logout(user, msg = FALSE))
  }
  
  all_dt_params = c(datatype@dt_param, unlist(datatype@dt_sel_option_params))
  
  if (!quiet)
    message("connecting to CliFlo...")
  if (nrow(station) > 20){
    station = station[1:20]
    message("using the first 20 stations")
  }
  doc = POST(url = "https://cliflo.niwa.co.nz/pls/niwp/wgenf.genform1_proc",
             query = as.list(c(
               cselect = "wgenf.genform1?fset=defdtype",
               auswahl = "wgenf.genform1?fset=defagent",
               agents = paste(station$agent, collapse = ","),
               dateauswahl = "wgenf.genform1?fset=defdate",
               date1_1=year(start_date),
               date1_2=month(start_date),
               date1_3=day(start_date),
               date1_4=hour(start_date),
               date2_1=year(end_date),
               date2_2=month(end_date),
               date2_3=day(end_date),
               date2_4=hour(end_date),
               formatselection = "wgenf.genform1?fset=deffmt",
               TSselection = output_tz,
               dateformat = "0",
               Splitdate = "N",
               mimeselection = "tabplain",
               cstn_id = "N",
               cdata_order = "SD",
               submit_sq = "Send Query",
               all_dt_params
               ))
             )
  
  stop_for_status(doc)

  if (!quiet)
    message("reading data...")

  all_lines = readLines(textConnection(content(doc, as = "text")))
  
  # If any line starts with the text 'No rows' then return an error.
  if (any(grepl("^No rows", all_lines)))
    stop(all_lines[grep("^No rows", all_lines)], call. = FALSE)

  # Search for lines that start with 'Station' so we know when the 
  # data begins.
  tables_start = tail(grep("^Station", all_lines), -1)
  
  # The data tables end with a blank line, but not the first 
  # nor the last 2...
  tables_end = tail(head(which(all_lines == ""), -2), -1)

  table_indices = mapply(seq, tables_start, tables_end, SIMPLIFY = FALSE)
  table_constant = rep(1, length(tables_end))
  table_constant[grepl("ls_fdly", datatype@dt_param, fixed = TRUE)] = 2
  table_constant[grepl("ls_f301", datatype@dt_param, fixed = TRUE)] = 3

  table_names = all_lines[tables_start - table_constant]
  
  # CliFlo doesn't have a table name for the soil moisture datatype. Create
  # one manually:
  table_names[which(grepl("soilm", datatype@dt_param))] = "Soil Moisture (20cm)"
  
  dt_names = sapply(strsplit(table_names, ":"), "[", 1)
  dt_types = sapply(strsplit(table_names, ":"), "[", 2)
  tail_msg = paste(all_lines[seq(grep("^UserName", all_lines), length(all_lines))],
                   collapse = "\n")
  
  # Fix the bad terms and conditions link in the tail message
  tail_msg = str_replace(tail_msg, 
                         "http://clifloecd1.niwa.co.nz/pls/niwp/doc/terms.html", 
                         "https://cliflo.niwa.co.nz/doc/terms.html")

  # Read the tab-delimited text into a list of dataframes
  data_list = lapply(table_indices, function(x)
    read.table(textConnection(all_lines[x]), sep = "\t", header = TRUE,
               na.strings = "-", check.names = FALSE))

  head_names = lapply(data_list, names)
  nrows = sapply(data_list, nrow)
  seq_ind =   which(nrows != 0)

  clifro_data_list = vector("list", length(seq_ind))

  for (i in seq_along(seq_ind)){
    clifro_data_list[[i]] = new("cfData",
                                dt_name = dt_names[seq_ind[i]],
                                dt_type = dt_types[seq_ind[i]],
                                names = head_names[[seq_ind[i]]],
                                row.names = paste(seq_len(nrows[seq_ind[i]])),
                                as(data_list[[seq_ind[i]]], "list"))
    clifro_data_list[[i]] = create_object(clifro_data_list[[i]])
  }
  if (!quiet)
    message(tail_msg)

  cf_data_list = new("cfDataList", clifro_data_list)

  if (length(clifro_data_list) == 1){
    set_history(cf_data_list[[1]])
    return(cf_data_list[[1]])
  }
  set_history(cf_data_list)
  cf_data_list
}
