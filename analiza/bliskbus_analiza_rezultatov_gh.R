# Arnesov HackathON

# filtriranje najbolj obremenjenih postaj na dnevnih linijah ob delavnikih 

library(rjson)

######### UVOZ PODATKOV #########

### povprečni čas postanka na dnevnih linijah ob delavnikih ###

# ročno izbrane datoteke za delavnike (zgenerirane s bliskbus_analiza_podatkov.R)
delavniki <- c("./lpp_povp_postanek_2024_03_21.csv",
               "./lpp_povp_postanek_2024_03_22.csv",
               "./lpp_povp_postanek_2024_03_25.csv",
               "./lpp_povp_postanek_2024_03_26.csv",
               "./lpp_povp_postanek_2024_03_27.csv",
               "./lpp_povp_postanek_2024_03_28.csv",
               "./lpp_povp_postanek_2024_04_03.csv",
               "./lpp_povp_postanek_2024_04_04.csv",
               "./lpp_povp_postanek_2024_04_05.csv",
               "./lpp_povp_postanek_2024_04_08.csv",
               "./lpp_povp_postanek_2024_04_09.csv",
               "./lpp_povp_postanek_2024_04_10.csv",
               "./lpp_povp_postanek_2024_04_11.csv",
               "./lpp_povp_postanek_2024_04_12.csv",
               "./lpp_povp_postanek_2024_04_24.csv",
               "./lpp_povp_postanek_2024_04_25.csv",
               "./lpp_povp_postanek_2024_04_25.csv")

# postaje mestnih linij z latitude in longitude range
# ustvarjeno s bliskbus_priprava_podatkov.R
postaje_mestnih_linij_range <- 
  list.files(path = "./trip_ids_range/", 
             full.names = TRUE, recursive = TRUE)

# seznams podatki o postajah na vsaki liniji
postaje_za_trip_id <- lapply(postaje_mestnih_linij_range, function(x){
  return(rjson::fromJSON(file = x))
})
names(postaje_za_trip_id) <- gsub(pattern = ".json", 
                                  replacement = "", 
                                  x = basename(postaje_mestnih_linij_range))

######### FUNKCIJE #########


#' Seznam vseh identifikacijskih številk postajališč
#'
#' @param linijske_datoteke json datoteke s postajami za vsako linijo
#'
#' @return dedupliciran seznam stop_id števil
postaje_id_st <- function(linijske_datoteke){
  post_ids <- lapply(postaje_mestnih_linij_range, function(x){
    postaje_ena_linija <- rjson::fromJSON(file = x)
    lapply(postaje_ena_linija, "[[", "stop_id")
  })
  return(unique(unlist(post_ids)))
}

######### ANALIZA #########

### zračunaj povprečni postanek ob vseh delavnikih ###

### seznam vseh stop_id (identifikacijskih številk postajališč) ###

postaje_ids <- postaje_id_st(postaje_mestnih_linij_range)

# združi povprečne postanke posameznih delavnikov
zacetni_df = data.frame(stop_id = postaje_ids)
for (x in delavniki){
  en_delavnik <- data.table::fread(x)
  zacetni_df <- merge(zacetni_df, en_delavnik, by = "stop_id", all = T)
}
# povpreči
povprecje <- rowMeans(zacetni_df[,2:ncol(zacetni_df)], na.rm=T)
povprecni_cas_delavnik <- data.frame(stop_id = zacetni_df$stop_id, povp_delavnik_postanek = povprecje)
# shrani
data.table::fwrite(povprecni_cas_delavnik, 
                   file = "./lpp_povp_postanek_delavnik_stop_id.csv", 
                   row.names = F)

### filtriraj primestne postaje ter začetne in končne postaje ###

# fitriraj mestne postaje

# narejeno v bliskbus_priprava_podatkov.R
postaje_mestne_linije_list <- rjson::fromJSON(file = "./postaje_z_mestnimi_linijami.json")
# ids mestnih potaj
povprecni_cas_delavnik_mestne <- povprecni_cas_delavnik[povprecni_cas_delavnik$stop_id %in% unlist(lapply(postaje_mestne_linije_list, "[[", "ref_id")),]

# filtraj začetne in končne postaje 
zacetne_koncne_postaje <- lapply(postaje_za_trip_id, function(x){
  prva <- x[[1]]$stop_id
  zadnja <- x[[length(x)]]$stop_id
  return(c(prva, zadnja))
})
# odstrani koncne in začetne postaje
povp_cas_imena_filt <- povprecni_cas_delavnik_mestne[!(povprecni_cas_delavnik_mestne$stop_id %in% unname(unlist(zacetne_koncne_postaje))),]

### dodaj imena postaj k stop_id ###

# dodaj imena
vse_postaje <- rjson::fromJSON(file = "./station-details.json")
test_df <- data.frame(imena = unlist(lapply(vse_postaje$data, "[[", "name")), stop_id = as.numeric(unlist(lapply(vse_postaje$data, "[[", "ref_id"))))
povp_cas_imena <- merge(x = povp_cas_imena_filt, y = test_df, x.by = "stop_id", y.by = "ref_id")
# shrani
data.table::fwrite(povp_cas_imena, 
                   file = "./lpp_povp_postanek_delavnik_stop_id_mestne.csv", 
                   row.names = F)
