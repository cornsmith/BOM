require(XML)
base_url <- "http://www.bom.gov.au"
setwd("./Data/")

# Get stations ------------------------------------------------------------
# download.file("http://www.bom.gov.au/climate/data/lists_by_element/alphaAUS_136.txt", destfile = "./Data/stations.txt")
stations <- read.delim("stations.txt", as.is = TRUE)
stations$StartYear <- as.integer(sapply(strsplit(stations$Start, " "), "[[", 2))
stations$EndYear <- as.integer(sapply(strsplit(stations$End, " "), "[[", 2))
# active stations
stations <- subset(stations, StartYear < 2015 & EndYear == 2016)

# Download and process ----------------------------------------------------
download_obs_file <- function(station, obs_code){
    if(!file.exists(paste0(obs_code, "_", station, ".zip"))){
        Sys.sleep(0.1)
        # goto station page for rainfall
        page <- htmlParse(paste0("http://www.bom.gov.au/jsp/ncc/cdio/weatherData/av?p_nccObsCode=", obs_code, "&p_display_type=dailyDataFile&p_startYear=&p_c=&p_stn_num=", station))
        
        # find the all years data link
        ziplink <- paste0(base_url, xpathSApply(page, "//a[@title='Data file for daily rainfall data for all years']", xmlGetAttr, "href"))
        
        # download and unzip
        download.file(ziplink, paste0(obs_code, "_", station, ".zip"), quiet = TRUE, mode = "wb")
    }
}

process_file <- function(station, years){
    temp_dir = "./temp"
    unzip(paste0(obs_code, "_", station, ".zip"), exdir = temp_dir)
    
    # read csv
    df <- read.csv(dir(temp_dir, pattern = ".csv", full.names = TRUE))
    df <- df[df$Year %in% years , 2:6]
    
    # delete csv
    file.remove(dir(temp_dir, full.names = TRUE))
    
    return(df)
}

# example
lapply(stations$Site, download_obs_file, obs_code = 136)

# df <- process_file(stations$Site[4], years = c(2015))
