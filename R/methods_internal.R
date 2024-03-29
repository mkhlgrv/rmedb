#' @include common.R
#' @include classes.R


setMethod(
  "download.ts", "internal",
  function(object) {
    if(object@ticker=='construction_real'|object@ticker=='services_real'){
      numenator_ts <- switch(object@ticker,
                          'construction_real' = 'construction_nom',
                          'services_real' = 'services_market')
      denominator_ts <- switch(object@ticker,
                          'construction_real' = 'ppi_construction',
                          'services_real' = 'ppi_services')
      file_name_numenator <- paste0(Sys.getenv('directory'), "/data/raw/", numenator_ts, ".csv")
      file_name_denominator <- paste0(Sys.getenv('directory'), "/data/raw/", denominator_ts, ".csv")
      numenator <- data.table::fread(file_name_numenator, colClasses = c("Date", "numeric", "Date")) %>%
        dplyr::group_by(date) %>%
        dplyr::filter(update_date == max(update_date)) %>%
        dplyr::ungroup()
      denominator <- data.table::fread(file_name_denominator, colClasses = c("Date", "numeric", "Date"))%>%
        dplyr::group_by(date) %>%
        dplyr::filter(update_date == max(update_date)) %>%
        dplyr::ungroup()
      object@ts <- numenator
      object@ts$value <- (numenator$value/cumprod(denominator$value/100))/
        (numenator$value/cumprod(denominator$value/100))[1]*100

    } else {
      file_name <- paste0(Sys.getenv('directory'), "/data/raw/", object@related_ticker, ".csv")
      ts <- data.table::fread(file_name, colClasses = c("Date", "numeric", "Date"))
      if(grepl("_montly",object@ticker)){
        agg_fun <- function(x, ticker){
          if(ticker=='fer_montly'){
            dplyr::arrange(x, date) %>%
              dplyr::mutate(x, value = last(value,na.rm=TRUE))
          } else{
            dplyr::mutate(x, value = mean(value,na.rm=TRUE))
          }
        }
        ts <- ts %>%
          dplyr::group_by(date) %>%
          dplyr::filter(update_date == max(update_date)) %>%
          dplyr::ungroup() %>%
          dplyr::arrange(dplyr::desc(date)) %>%
          dplyr::group_by(zoo::as.yearmon(date)) %>%
          agg_fun(ticker = object@ticker) %>%
          dplyr::filter(dplyr::row_number()==1) %>%
          dplyr::ungroup() %>%
          dplyr::select(1:3) %>%
          dplyr::arrange(date) %>%
          dplyr::mutate(date = zoo::as.Date(zoo::as.yearmon(date))) %>%
          dplyr::filter(date < max(date))


      }
      object@ts <- ts
    }


    validObject(object)
    return(object)
  }
)
