library(tidycensus)
library(tidyverse)
library(sf)

other_alone <- c("P2_010N")
black_alone <- c("P2_006N")
hisp <- c("P2_002N")
aapi_alone <- c("P2_008N","P2_009N")
white <- c("P2_005N")
native_alone <- "P2_007N"
multiracial <- "P2_011N"

all_vars_2 <-c(black_alone,aapi_alone,hisp,white,multiracial,native_alone,other_alone)

fl_race_blocks <- tidycensus::get_decennial(
  geography = "block",
  state = "fl",
  variables = all_vars_2,
  summary_var = "P2_001N",
  year=2020,
  output = "wide",
  geometry = TRUE)

fl_race_blocks <- transform(fl_race_blocks,
                            black = P2_006N,
                            white = P2_005N,
                            hisp = P2_002N,
                            AAPI = P2_008N+
                              P2_009N,
                            native = P2_007N,
                            other = P2_010N,
                            multi = P2_011N)

vars_to_keep <- vars_to_keep <- c("GEOID","NAME",
                                  #"summary_value",
                                  "black","white","hisp","AAPI","native","other","multi","geometry")

fl_race_blocks <- fl_race_blocks[vars_to_keep]

rm(vars_to_keep)
rm(all_vars_2)

#write shapefile
write_sf(fl_race_blocks,"fl_race_blocks.shp")

#later on if you're starting again, just read the pre-written shapefile
fl_race_blocks <- read_sf("fl_race_blocks.shp")


#count race populations and make sure they match state total
fl_race_blocks %>%   
  summarise(black=sum(black),white=sum(white),native=sum(native),hisp=sum(hisp),asian=sum(AAPI),other=sum(other),multi=sum(multi),total=sum(summary_value))

#### make race dots / WARNING: THIS MAY TAKE DAYS IF YOU DO THIS IN R AND NOT QGIS ####

library(ggthemes)
library(mapview)
library(tigris)
options(tigris_use_cache=TRUE)

race_pivot <- fl_race_blocks %>% 
  pivot_longer(cols=3:9,names_to = "variabl",values_to="estimat")
rm(fl_race_blocks)

# create function for samples ####
generate_samples <- function(data)
  suppressMessages(sf::st_sample(data, size = round(data$estimat / 50)))

race_split <- race_pivot %>% 
  split(.$variabl)
rm(race_pivot)

#create points ####
points <- purrr::map(race_split, generate_samples)
rm(race_split)
points <- imap(points, 
               ~st_sf(data_frame(variabl = rep(.y, length(.x))),
                      geometry = .x))

points <- do.call(rbind, points)

points <- points %>% group_by(variabl) %>% summarise()

points <- points %>%
  mutate(variabl = factor(
    variabl,
    levels = c("black","white","hisp","AAPI","native","other","multi")))


# view how many points are in each layer, verify number matches state totals
points %>% 
  mutate(n_points = map_int(geometry, nrow)) %>% 
  arrange(desc(n_points))

#create points shapefile
write_sf(points,"fl_points.shp")


#create Mapbox tiles format
mapboxapi::tippecanoe(input=points,output="points.mbtiles",layer_name="points")
mapboxapi::upload_tiles(input="points",username)

