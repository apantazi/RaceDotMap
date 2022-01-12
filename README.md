# RaceDotMap
This variation of the RaceDotMap includes fewer racial categories and focuses on Duval County for our [redistricting map](https://data.jaxtrib.org/jacksonville_redistricting).

This map overlays the redistricting proposal over 2020 Census data and 2020 presidential election data from the Duval County Supervisor of Elections.

The map used 2020 Census data at the census block level to generate one dot for every person who lives there for the racial data. The map also used precinct-level 2020 election for Duval's 199 precincts. I combined land-use maps with the precinct shapefile to generate votes randomly over residential and mixed-use zoned property to estimate where Biden, Trump and Other voters live.

This provides a valuable tool to see how the proposed redistricting plan packs in Black and Democratic voters into four districts in particular.

Below, I provide a roadmap for building the race-dot map using R, QGIS, Tippecanoe and Mapbox.

## Part 1 in R
###
Start by collecting your Census data using the most updated TidyCensus library in R.

### libraries
library(tidycensus)
library(tidyverse)
library(sf)
options(tigris_use_cache = TRUE)

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
  county = "duval",
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
                            other = P2_007N + P2_010N + P2_011N)


vars_to_keep <- vars_to_keep <- c("GEOID","NAME",
                                  "black","white","hisp","AAPI","other",
                                  "geometry")

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

Make sure your projection is EPSG:4326 in the bottom-right corner of the window.

Export your points layer to a GEOJSON file.

## Part 3 - Tippecanoe

Ensure you have Tippecanoe properly installed on your computer. I used Ubuntu, so I'll show what I used from that.

### Open Ubuntu Console

cd to your folder with the geojson file.

Run this code: tippecanoe -Z10 -o OUTPUT.mbtiles -f -pc -pf -r1 -aC INPUT.geojson

### Upload to Mapbox
Go back to R and use the mapboxapi package.

libarary(mapboxapi)

upload_tiles(
  access_token = "TOKEN",
             input="INPUT",
             tileset_id = "race_shp_2020",
             username = "USERNAME",
             multipart = TRUE)


You can then upload a shapefile of the redistricting plan to Mapbox, and in Mapbox Studio, overlay both the race dots and the lines for the redistricting plan. 
