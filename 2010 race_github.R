library(tidycensus)
library(tidyverse)
library(mapview)
library(tigris)

options(tigris_use_cache=TRUE)

v16 <- load_variables(2010, "sf1", cache = TRUE)

other_alone <- c("P009010")

black_alone <- c("P009006")

hisp <- c("P009002")

aapi_alone <- c("P009008","P009009")

white <- c("P009005")

native_alone <- "P009007"

multi_alone <- "P009011"

all_vars_2 <-c(black_alone,aapi_alone,hisp,white,multi_alone,native_alone,other_alone)

fl_race_blocks <- tidycensus::get_decennial(
  geography = "block",
  state = "fl",
  variables = all_vars_2,
  summary_var = "P002001",
  year=2010,
  output = "wide",
  geometry = TRUE)

fl_race_blocks <- transform(fl_race_blocks,
                            black = P009006,
                            white = P009005,
                            hisp = P009002,
                            AAPI = P009008+
                              P009009,
                            native = P009007,
                            other = P009010,
                            multi = P009011)

#test the data - should say total = 21538187 / black = 41,104,200 / hispanic = 5,697,240 / native = 94,795 / aapi = 657696
fl_race_blocks %>% 
  summarise(black=sum(black),white=sum(white),native=sum(native),hisp=sum(hisp),asian=sum(AAPI),other=sum(other),multi=sum(multi),total=sum(summary_value))


vars_to_keep <- vars_to_keep <- c("black","white","hisp","AAPI","native","other","multi","GEOID","NAME","geometry")
fl_race_blocks <- fl_race_blocks[vars_to_keep]

library(sf)
write_sf(fl_race_blocks,"2010_fl_race_blocks.shp")
fl_race_blocks <- read_sf("2010_fl_race_blocks.shp")

#### WARNING - THIS IS CODE THAT TAKES A LONG TIME TO PROCESS ####

fl_counties <- c("001", 
                 "003", 
                 "005", 
                 "007", 
                 "009", 
                 "011", 
                 "013", 
                 "015", 
                 "017", 
                 "019", 
                 "021", 
                 "023", 
                 "027", 
                 "029", 
                 "031", 
                 "033", 
                 "035", 
                 "037", 
                 "039", 
                 "041", 
                 "043", 
                 "045", 
                 "047", 
                 "049", 
                 "051", 
                 "053", 
                 "055", 
                 "057", 
                 "059", 
                 "061", 
                 "063", 
                 "065", 
                 "067", 
                 "069", 
                 "071", 
                 "073", 
                 "075", 
                 "077", 
                 "079", 
                 "081", 
                 "083", 
                 "085", 
                 "086", 
                 "087", 
                 "089", 
                 "091", 
                 "093", 
                 "095", 
                 "097", 
                 "099", 
                 "101", 
                 "103", 
                 "105", 
                 "107", 
                 "109", 
                 "111", 
                 "113", 
                 "115", 
                 "117", 
                 "119", 
                 "121", 
                 "123", 
                 "125", 
                 "127", 
                 "129", 
                 "131", 
                 "133")

fl_roads <- tigris::roads("fl",fl_counties,year=2011)

fl_clipped <- st_difference(fl_race_blocks,fl_roads)
rm(fl_roads)
fl_water <- tigris::area_water("fl",fl_counties,year=2011)

fl_clipped <- st_difference(fl_race_blocks,fl_water)

#### race dots ####
race_pivot <- fl_race_blocks %>% 
  pivot_longer(cols=1:7,names_to = "variabl",values_to="estimat")
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


# view how many points are in each layer
points %>% 
  mutate(n_points = map_int(geometry, nrow)) %>% 
  arrange(desc(n_points))

write_sf(points,"fl_points_2010.shp")