require(XML)
base_url <- "http://www.bom.gov.au"
setwd("./Data/")

# Get stations ------------------------------------------------------------
# download.file("http://www.bom.gov.au/climate/data/lists_by_element/alphaAUS_136.txt", destfile = "./Data/stations.txt")
stations <- read.delim("stations.txt", as.is = TRUE)
stations$StartYear <- as.integer(sapply(strsplit(stations$Start, " "), "[[", 2))
stations$EndYear <- as.integer(sapply(strsplit(stations$End, " "), "[[", 2))
# active stations
stations <- subset(stations, StartYear < 2014 & EndYear == 2016)

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
        
        print(station)
    }
}

process_file <- function(filename, years){
    temp_dir = "./temp"
    unzip(filename, exdir = temp_dir)
    
    datafilename <- dir(temp_dir, pattern = ".csv", full.names = TRUE)
    
    if(length(datafilename) == 1){
        # read csv
        df <- read.csv(datafilename)
        df <- df[df$Year %in% years, 2:6]
    } else {
        df <- 0
    }
    # delete csv
    file.remove(dir(temp_dir, full.names = TRUE))
    
    return(df)
}

# Process -----------------------------------------------------------------
# 136, 122, 123, 193
lapply(stations$Site, download_obs_file, obs_code = 122)
df <- lapply(dir(pattern = "136_([0-9]{4,5}).zip"), process_file, years = c(2014, 2015))
data <- do.call("rbind", df)
data <- data[data$Year != 0, ]

save(data, file = "BOM.RData")

