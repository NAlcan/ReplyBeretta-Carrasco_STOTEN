## Libraries call ----
library(tidyverse) # arreglar datos (dplyr) y graficar (ggplot2)
library(sf) # simple features para trabajar con datos espaciales
library(mapsf) # helps to design various cartographic representations
library(geouy) # easily access official spatial data sets of Uruguay
library(ggspatial)
library(viridis) # color palette
library(snakecase) # clean levels names of categorical variables

#devtools::install_github("yutannihilation/ggsflabel") # Experimental packages for better labelling of sf maps
library(ggsflabel)
###

# Data sites --------------------------------------------------------------
# Load data site and project as points
sites <- read_csv("2.Datos/gis_data/coordenadas_sitios.csv")

# Convert it to spacial object with crs projection
sites_longlat <- sites %>%
  st_as_sf (coords = c("longitud", "latitud")) %>%
  st_sf (crs = 4326)


# Load Uruguay border catrography from package `geouy`
borders <- load_geouy("Uruguay")

rivers <-
  load_geouy("Cursos de agua navegables y flotables") %>% # Rivers cartography
  st_cast("MULTILINESTRING") # Convert multicurve to multistring https://github.com/r-spatial/sf/issues/1194

# Selected rivers and streams to plot
# A vector with river names separated by conditional symbol "|"
this_rivers <- paste(
  "uruguay",
  "cuareim",
  "río_negro",
  "tacuarembó",
  "tacuarembó_chico",
  "de_la_plata",
  "san_salvador",
  sep = "|"
)

#
study_rivers <- rivers %>%
  mutate(nombre = to_snake_case(nombre)) %>%
  filter(str_detect(nombre, this_rivers))

# Reservoirs and lagoons cartography dowloaded from DIva-Gis Free Spatial Data at country level `http://diva-gis.org/gdata`
water_bodies <-
  st_read ("2.Datos/gis_data/ury_inlandwater") %>%  # Uruguay/InlandWater
  mutate (name = to_snake_case(NAME),
          .keep = "unused") %>%  # te drop de old NAME column and retain the new one
  filter(name %in% c("rio_uruguay_uruguay", "embalse_del_rio_negro"))

# base map
base_map <- ggplot() +
  geom_sf (data = borders, fill = "NA", color = "grey40") +
  geom_sf (data = study_rivers, color = "#1f78b4") +
  geom_sf (data = water_bodies, color = "#1f78b4") +
  theme_bw() +
  theme(panel.grid = element_blank())

# Edit Rivers names to add a plot maintaining its x,y coorde

river_labels <- study_rivers %>%
  mutate(
    name = fct_recode(
      nombre,
      `Tbo Chico river` = "arroyo_tacuarembó_chico",
      `Negro river` = "río_negro",
      `Uruguay river` = "río_uruguay",
      `Cuareim river` = "río_cuareim",
      `San Salvador river` = "río_san_salvador",
      `Tbo river` = "río_tacuarembó",
      `Río de la Plata` = "río_de_la_plata"
    )
  )

# Map with site points filled if are used or not into BC2011

mapa_listo <-  base_map +
  geom_sf(
    data = sites_longlat,
    aes(fill = type, shape = type),
    size = 1.5,
    color = "black"
  ) +
  scale_fill_viridis(option = "magma", discrete = T) +
  scale_shape_manual(values = c(21, 22, 23), guide = "legend") +
  labs (fill = "Legend", shape = "Legend",) +
  annotation_scale(location = "br",
                   width_hint = 0.2,
                   text_cex = 0.8) +
  annotation_north_arrow(
    location = "br",
    which_north = "true",
    height = unit(1, "cm"),
    width = unit(1, "cm"),
    pad_y = unit(0.45, "cm"),
    style = north_arrow_fancy_orienteering
  ) +
  labs (x = "longitude", y = "latitude") +
  theme(legend.position = c(0.81, 0.85),
        legend.background  = element_blank()) +
  geom_sf_text(
    data = river_labels,
    aes(label = name),
    size = 3,
    fontface = "bold",
    family = "serif",
    hjust = c(
      `Tbo Chico river` = .7,
      `Negro river` =  .2,
      `Uruguay river` = 1,
      `Cuareim river` =  .3,
      `San Salvador river` = -.5,
      `Tbo river` = .3,
      `Río de la Plata` = 0.8
    ) ,
    vjust = c(
      `Tbo Chico river` = 1.8,
      `Negro river` =  3,
      `Uruguay river` = 1.7,
      `Cuareim river` =  -1.2,
      `San Salvador river` = 0,
      `Tacuarembó river` = -1.8,
      `Río de la Plata` = 2
    ),
    angle = c(
      `Tbo Chico river` = 310,
      `Negro river` =  0,
      `Uruguay river` = 260,
      `Cuareim river` =  320,
      `San Salvador river` = 340,
      `Tacuarembó river` = 300,
      `Río de la Plata` = 0
    ) 
  )




# # Generate a character with equivalencies between number site and its code
caption_sites <- paste(sites_longlat$site_number,
                       sites_longlat$codigo_estacion,
                       sep = " = ") %>%
  str_c(., collapse = ", ")


vers1 <- mapa_listo +
  geom_sf_text_repel(
    data = sites_longlat,
    aes(label = site_number),
    size = 2,
    max.overlaps = 20,
    box.padding = unit(0.1, "lines")
  )

# Save in tiff format
ggsave(vers1, filename = "3.Resultados/Figure2.tiff")

# to save in .svg format
#ggsave(vers1, filename = "3.Resultados/map_siterivers_svg.svg")


# eps output #
# To save in eps need to comment l87: family = "sans"
# in not it gives an ERORR!
#ggsave(vers1, filename = "3.Resultados/map_siterivers_eps.eps")