#' A search function for hydrometric station name or number
#'
#' Use this search function when you only know the partial station name or want to search.
#'
#' @param search_term Only accepts one word.
#' @inheritParams hy_agency_list
#'
#' @return A tibble of stations that match the \code{search_term}
#' 
#' @examples 
#' \dontrun{
#' search_stn_name("Cowichan")
#' 
#' search_stn_number("08HF")
#' }
#'
#' @export

search_stn_name <- function(search_term, hydat_path = NULL) {
  
  ## Read in database
  hydat_con <- hy_src(hydat_path)
  if (!dplyr::is.src(hydat_path)) {
    on.exit(hy_src_disconnect(hydat_con))
  }
  
  results <- realtime_stations() %>%
    dplyr::bind_rows(suppressMessages(hy_stations(hydat_path = hydat_con))) %>%
    dplyr::distinct(.data$STATION_NUMBER, .keep_all = TRUE) %>%
    dplyr::select(.data$STATION_NUMBER, .data$STATION_NAME, .data$PROV_TERR_STATE_LOC, .data$LATITUDE, .data$LONGITUDE)
  
  results <- results[grepl(toupper(search_term), results$STATION_NAME), ]
  
  if (nrow(results) == 0) {
    message("No station names match this criteria!")
  } else {
    results
  }
}

#' @rdname search_stn_name
#' @export
#' 
search_stn_number <- function(search_term, hydat_path = NULL) {
  
  ## Read in database
  hydat_con <- hy_src(hydat_path)
  if (!dplyr::is.src(hydat_path)) {
    on.exit(hy_src_disconnect(hydat_con))
  }
  
  results <- realtime_stations() %>%
    dplyr::bind_rows(suppressMessages(hy_stations(hydat_path = hydat_con))) %>%
    dplyr::distinct(.data$STATION_NUMBER, .keep_all = TRUE) %>%
    dplyr::select(.data$STATION_NUMBER, .data$STATION_NAME, .data$PROV_TERR_STATE_LOC, .data$LATITUDE, .data$LONGITUDE)
  
  results <- results[grepl(toupper(search_term), results$STATION_NUMBER), ]
  
  if (nrow(results) == 0) {
    message("No station number match this criteria!")
  } else {
    results
  }
}

#' @title Wrapped on rappdirs::user_data_dir("tidyhydat")
#'
#' @description A function to avoid having to always type rappdirs::user_data_dir("tidyhydat")
#' 
#' @param ... arguments potentially passed to \code{rappdirs::user_data_dir}
#' 
#' @examples \dontrun{
#' hy_dir()
#' }
#'
#' @export
#'
#'
hy_dir <- function(...){
  rappdirs::user_data_dir("tidyhydat")
}

#' hy_agency_list function
#'
#' AGENCY look-up Table
#' 
#' @param hydat_path The path to the hydat database or NULL to use the default location
#'   used by \link{download_hydat}. It is also possible to pass in an existing 
#'   \link[dplyr]{src_sqlite} such that the database only needs to be opened once per
#'   user-level call.
#'
#' @return A tibble of agencies
#'
#' @family HYDAT functions
#' @source HYDAT
#' @export
#' @examples
#' \dontrun{
#' hy_agency_list()
#'}
#'
hy_agency_list <- function(hydat_path = NULL) {
  
  ## Read in database
  hydat_con <- hy_src(hydat_path)
  if (!dplyr::is.src(hydat_path)) {
    on.exit(hy_src_disconnect(hydat_con))
  }

  agency_list <- dplyr::tbl(hydat_con, "AGENCY_LIST") %>%
    dplyr::collect()

  agency_list
}


#'  Extract regional office list from HYDAT database
#'
#'  OFFICE look-up Table
#' @inheritParams hy_agency_list
#' @return A tibble of offices
#'
#' @family HYDAT functions
#' @source HYDAT
#' @export
#' @examples
#' \dontrun{
#' hy_reg_office_list()
#'}
#'
#'
hy_reg_office_list <- function(hydat_path = NULL) {
  
  ## Read in database
  hydat_con <- hy_src(hydat_path)
  if (!dplyr::is.src(hydat_path)) {
    on.exit(hy_src_disconnect(hydat_con))
  }

  regional_office_list <- dplyr::tbl(hydat_con, "REGIONAL_OFFICE_LIST") %>%
    dplyr::collect()
  
  regional_office_list
}

#'  Extract datum list from HYDAT database
#'
#'  DATUM look-up Table
#' @inheritParams hy_agency_list
#'
#' @return A tibble of DATUMS
#'
#' @family HYDAT functions
#' @source HYDAT
#' @examples
#' \dontrun{
#' hy_datum_list()
#'}
#'
#' @export
#'
hy_datum_list <- function(hydat_path = NULL) {
  ## Read in database
  hydat_con <- hy_src(hydat_path)
  if (!dplyr::is.src(hydat_path)) {
    on.exit(hy_src_disconnect(hydat_con))
  }
  
  datum_list <- dplyr::tbl(hydat_con, "DATUM_LIST") %>%
    dplyr::collect()
  
  datum_list
}


#' Extract version number from HYDAT database
#' 
#' A function to get version number of hydat
#'
#' @inheritParams hy_agency_list
#'
#' @return version number and release date
#'
#' @family HYDAT functions
#' @source HYDAT
#' @export
#' @examples
#' \dontrun{
#' hy_version()
#'}
#'
#'
hy_version <- function(hydat_path = NULL) {
  
  ## Read in database
  hydat_con <- hy_src(hydat_path)
  if (!dplyr::is.src(hydat_path)) {
    on.exit(hy_src_disconnect(hydat_con))
  }
  
  version <- dplyr::tbl(hydat_con, "VERSION") %>%
    dplyr::collect() %>%
    dplyr::mutate(Date = lubridate::ymd_hms(.data$Date))
  
  version
  
}

#' Calculate daily means from higher resolution realtime data
#' 
#' This function is meant to be used within a pipe as a means of easily moving from higher resolution 
#' data to daily means.
#' 
#' @param data A data argument that is designed to take only the output of realtime_dd
#' @param na.rm a logical value indicating whether NA values should be stripped before the computation proceeds.
#' 
#' @examples
#' \dontrun{
#' realtime_dd("08MF005") %>% realtime_daily_mean()
#' }
#' 
#' @export
realtime_daily_mean <- function(data, na.rm = FALSE){
  
  df_mean <- dplyr::mutate(data, Date = as.Date(.data$Date))
  
  df_mean <- dplyr::group_by(df_mean, .data$STATION_NUMBER, .data$PROV_TERR_STATE_LOC, .data$Date, .data$Parameter)
  
  dplyr::summarise(df_mean, Value = mean(.data$Value, na.rm = na.rm)) %>%
    dplyr::ungroup()
}
