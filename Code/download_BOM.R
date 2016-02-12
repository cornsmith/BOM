require(XML)
base_url <- "http://www.bom.gov.au"
setwd("./Data/")

# Get stations ------------------------------------------------------------
# download.file("http://www.bom.gov.au/climate/data/lists_by_element/alphaAUS_136.txt", destfile = "./Data/stations.txt")
stations <- read.delim("stations.txt", as.is = TRUE)

download_rainfall <- function(station){
    temp_dir = "./temp"
    
    # goto station page for rainfall
    page <- htmlParse(paste0("http://www.bom.gov.au/jsp/ncc/cdio/weatherData/av?p_nccObsCode=136&p_display_type=dailyDataFile&p_startYear=&p_c=&p_stn_num=", station))
    
    # find the all years data link
    ziplink <- paste0(base_url, xpathSApply(page, "//a[@title='Data file for daily rainfall data for all years']", xmlGetAttr, "href"))
    
    # download and unzip
    download.file(ziplink, paste0(station, ".zip"), mode = "wb")
    unzip(paste0(station, ".zip"), exdir = temp_dir)
    
    # read csv and delete
    df <- read.csv(dir(temp_dir, pattern = ".csv", full.names = TRUE))
    file.remove(dir(temp_dir, full.names = TRUE))
    
    return(df)
}

# example
download_rainfall(stations$Site[4])


