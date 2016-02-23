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
        node_title <- c(
            "Data file for daily rainfall data for all years",
            "Data file for daily maximum temperature data for all years",
            "Data file for daily minimum temperature data for all years",
            "Data file for daily global solar exposure data for all years"
        )[match(obs_code, c(136, 122, 123, 193))]
        ziplink <- paste0(base_url, xpathSApply(page, paste0("//a[@title='", node_title, "']"), xmlGetAttr, "href"))
        
        # download and unzip
        if(ziplink != base_url){
            download.file(ziplink, paste0(obs_code, "_", station, ".zip"), quiet = TRUE, mode = "wb")
        }
        
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
lapply(stations$Site, download_obs_file, obs_code = 136)
df <- lapply(dir(pattern = "136_([0-9]{4,5}).zip"), process_file, years = c(2014, 2015))
data_rain <- do.call("rbind", df)
data_rain <- data_rain[data_rain$Year != 0, ]
rm(df)

lapply(stations$Site, download_obs_file, obs_code = 122)
df <- lapply(dir(pattern = "122_([0-9]{4,5}).zip"), process_file, years = c(2014, 2015))
data_temp_max <- do.call("rbind", df)
data_temp_max <- data_temp_max[data_temp_max$Year != 0, ]
rm(df)

lapply(stations$Site, download_obs_file, obs_code = 123)
df <- lapply(dir(pattern = "123_([0-9]{4,5}).zip"), process_file, years = c(2014, 2015))
data_temp_min <- do.call("rbind", df)
data_temp_min <- data_temp_min[data_temp_min$Year != 0, ]
rm(df)

lapply(stations$Site, download_obs_file, obs_code = 193)
df <- lapply(dir(pattern = "193_([0-9]{4,5}).zip"), process_file, years = c(2014, 2015))
data_solar <- do.call("rbind", df)
data_solar <- data_solar[data_solar$Year != 0, ]
rm(df)

save(data_rain, file = "rain_2014-2015.RData")
save(data_temp_min, file = "tempmin_2014-2015.RData")
save(data_temp_max, file = "tempmax_2014-2015.RData")
save(data_solar, file = "solar_2014-2015.RData")


df <- merge(data_rain, data_solar, all = TRUE)
df <- merge(df, data_temp_min, all = TRUE)
df <- merge(df, data_temp_max, all = TRUE)
save(df, file = "BOM.RData")

write.csv(df, "2014-2015.csv", na = "", row.names = FALSE)
