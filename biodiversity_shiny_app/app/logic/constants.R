#' @export
db_data_location <- "app/data"


#' @export
main_query <- "
  SELECT
    id, scientificName, vernacularName, taxonRank, kingdom,
    continent, country, countryCode, eventDate,
    latitudeDecimal, longitudeDecimal
  FROM '%s'
  WHERE vernacularName IN (%s) OR scientificName IN (%s)
"

#' @export
unique_options_query <- "
  SELECT DISTINCT vernacularName FROM '%s'
  UNION
  SELECT DISTINCT scientificName FROM '%s'
"

#' @export
summary_query <- "
  SELECT
    country,
    scientificName,
    vernacularName,
    DATE_TRUNC('month', CAST(eventDate AS DATE)) AS event_month,
    COUNT(*) AS observation_count
  FROM '%s'
  WHERE vernacularName IN (%s) OR scientificName IN (%s)
  GROUP BY country, event_month, scientificName, vernacularName
  ORDER BY event_month;
"
