# Arnesov HackathON

# priprava podatkov za analizo najbolj obremenjenih postaj

######### UVOZ ARGUMENTOV IZ UKAZNE VRSTICE #########

args <- commandArgs(trailingOnly = TRUE)

trip_ids_arg <- args[1]  # trip_ids.json
postaje_arg <- args[2]   # station-details.json
postaje_mestnih_linij_arg <- args[3] # /postajalisca_of_tripid/
out_arg <- args[4] # .

######### KNJIŽNICE #########

library(rjson)

######### UVOZ PODATKOV #########

# slovar "trip_id" in "line_num"
trip_ids <- rjson::fromJSON(file = trip_id_args)
# vse postaje lpp
postaje <- rjson::fromJSON(file = postaje_arg)$data
# datoteke s postajami za vsak trip_id (ime linije)
postaje_mestnih_linij <- list.files(path = postaje_mestnih_linij_arg, 
                                    full.names = TRUE, recursive = TRUE)

######### PRIPRAVA POATKOV #########


### izberi samo postaje mestnih linij in jih shrani kot json datoteko ###

mestne_check <- lapply (postaje, function(x){
  any(x$route_groups_on_station %in% c("1", "1B", "N1", "2", "3", "3B", "3G", "N3", "N3B", "5", "N5", "6", "6B", 
                                         "7", "7L", "8", "9", "10", "11", "11B", "12", "12D", "13", "14", "15", "16", 
                                         "18", "18L", "19B", "19I", "20", "20Z", "21", "21Z", "22", "23", "24", "25", 
                                         "26", "27", "SŽ", "30", "51", "52", "53", "56", "60", "61"))
})
mestne_postaje <- postaje[unlist(mestne_check)]
mestne_postaje_json <- rjson::toJSON(mestne_postaje)
write(mestne_postaje_json, paste0(out_args + "postaje_z_mestnimi_linijami.json"))


### določi velike in majhne postaje ###


# vse postaje na katerih se ustavljajo mestne linije (ustvarjeno v prejšnjem koraku)
postaje_mestne_linije_list <- mestne_postaje_json

## najdi postaje, ki so dovolj dolge, da sprejmejo 3 dolge avtobuse
# izberi tiste postaje, ki imajo več kot 3 linije
busi_na_postaji <- lapply(postaje_mestne_linije_list, "[[", "route_groups_on_station")
velike_postaje_TF <- lapply(busi_na_postaji, function(x){
  return(length(x)>3)
})
velike_postaje <- postaje_mestne_linije_list[unlist(velike_postaje_TF)]
lapply(velike_postaje, "[[", "name")
# te postaje so bile ročno pregledane in izbrane so bile tiste, ki so dovolj dolge, da sprejmejo 3 dolge avtobuse 
velike_postaje_imena <- c("Razstavišče", "Bežigrad", "Kolodvor", 
                          "Ljubljana AP", "Zaloška", "Bavarski dvor", 
                          "Ajdovščina", "Pošta", "Konzorcij", 
                          "Kino Šiška", "Šentvid")


### dodaj razpon latitute in longitude postaje v katerem bo avtobus veljal, da je na postaji ###


# en velik avtobus s harmoniko je dolg 20m, velike postaje spremejo do 3 - 60m
# to bo polmer, saj je lahko lokacija postaje na začetku ali koncu dejanske postaje

# majhne postaje sprejmejo do 2 velika avtobusa - polmer bo 30m

## pretvorba dolžine v stopinje 

# 60m v latitute 1 = 111320, x = 60
60/111320 #= 0.0005389867
# 30m v latitute 1 = 111320, x = 30
30/111320 #= 0.0002694934

# 60m v longitude 1 = (40075 km/360)* cos(latitude), x = 60
# 40075 * cos(46.05108000) / 360 # 1 stopinja je -53.17258km
60/((40075000*cos(46.05108000))/360) #= -0.001128401
# 30m v longitude 1 = (40075 km/360)* cos(latitude), x = 30
30/((40075000*cos(46.05108000))/360) #= -0.0005642006

# postajam dodamo latitude_range <- c(min, max) in longitude_range <- c (min, max)
for (x in 1:length(postaje_mestnih_linij)){   # zankaj čez postaje
  postaje_trip <- rjson::fromJSON(file = postaje_mestnih_linij[[x]])
  for (y in 1:length(postaje_trip)){
    # če je postaja velika, je polmer 60m (pretvorjeno v stopinje, en avtobus s harmoniko je 20m)
    if (postaje_trip[[y]]$name %in% velike_postaje_imena) {
      postaje_trip[[y]]$latitude_range <- c(postaje_trip[[y]]$lat - 0.00054, postaje_trip[[y]]$lat + 0.00054)
      postaje_trip[[y]]$longitude_range <- c(postaje_trip[[y]]$lng - 0.00113, postaje_trip[[y]]$lng +  0.00113)
      # če je postaja majhna, je polmer 30m (pretvorjeno v stopinje, en avtobus s harmoniko je 20m)
    } else {
      postaje_trip[[y]]$latitude_range <- c(postaje_trip[[y]]$lat - 0.00027, postaje_trip[[y]]$lat + 0.00027)
      postaje_trip[[y]]$longitude_range <- c(postaje_trip[[y]]$lng - 0.00056, postaje_trip[[y]]$lng +  0.00056)
    }
  }
  # #print(postaje_trip)
  # #print(seznam_postaj)
  #print(basename(postaje_mestnih_linij[[x]]))
  write(toJSON(postaje_trip), paste0(out_arg, basename(postaje_mestnih_linij[[x]])))
}


# sledi pretvorba v eno datoteko na en abtobus na dan s python skripto



