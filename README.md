# RaceDotMap

## Part 1 in R
###
Start by collecting your Census data using the most updated TidyCensus library in R.

### libraries
library(tidycensus)

library(tidyverse)

library(sf)

### variables
other_alone <- c("P2_010N")

black_alone <- c("P2_006N")

hisp <- c("P2_002N")

aapi_alone <- c("P2_008N","P2_009N")

white <- c("P2_005N")

native_alone <- "P2_007N"

multiracial <- "P2_011N"

all_vars_2 <-c(black_alone,aapi_alone,hisp,white,multiracial,native_alone,other_alone)


### read your data

fl_race_blocks <- tidycensus::get_decennial(
  geography = "block",
  state = "fl",
  variables = all_vars_2,
  summary_var = "P2_001N",
  year=2020,
  output = "wide",
  geometry = TRUE)

### transform your data
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
                                  "black","white","hisp","AAPI","native","other","multi","geometry")

fl_race_blocks <- fl_race_blocks[vars_to_keep]

rm(vars_to_keep)

rm(all_vars_2)

### write your data
write_sf(fl_race_blocks,"fl_race_blocks.shp")


## Part 2 - QGIS

Read your shapefile into QGIS with "Add Vector Layer…"
Next, randomly assign points to polygons with Vector > Research Tools > Random Points Inside Polygons.
- Select the shapefile as your polygon layer.
- Next to "number of points for each feature" click the button for data defined override, then under Attribute Field, select "black"
- Click "run"
- Repeat for the other attribute fields

Go to Vector > Data Management Tools > Merge Vector Layers
Select each of the racial attribute fields.
Run

Make sure your projection is EPSG:3857 in the bottom-right corner of the window.

Export your points layer to a JSON file.

## Part 3 - Tippecanoe

Ensure you have Tippecanoe properly installed on your computer. I used Ubuntu, so I'll show what I used from that.

### Open Ubuntu Console

cd to your folder with the json file.

Run this code: tippecanoe -Z6 -z16 -o OUTPUT.mbtiles -f --drop-fraction-as-needed --extend-zooms-if-still-dropping INPUT.geojson

### Upload to Mapbox
Go back to R and use the mapboxapi package.

libarary(mapboxapi)

upload_tiles(
  access_token = "TOKEN",
             input="INPUT",
             tileset_id = "race_shp_2020",
             username = "USERNAME",
             multipart = TRUE)
