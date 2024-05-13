# Arnesov HackathON

# analiza najbolj obremenjenih postaj

######### UVOZ ARGUMENTOV IZ UKAZNE VRSTICE #########

args <- commandArgs(trailingOnly = TRUE)

postaje_mestnih_linij_arg <- args[1] # /postajalisca_of_tripid/
out_arg <- args[2]                   # .
dnevi_mape_arg <- args[3:len(args)]  # /2024_04_09/bus_id/ iod.

######### KNJIŽNICE #########

library(rjson)
library(parallel)

######### UVOZ PODATKOV #########


# postaje mestnih linij s latitude in longitude range
# ustvarjeno s bliskbus_priprava_podatkov.R
postaje_mestnih_linij_range <- 
  list.files(path = postaje_mestnih_linij_arg, 
             full.names = TRUE, recursive = TRUE)
# seznam json datotek z lokacijami za vsak avtobus v enem dnevu
# seznam_avtobusi_lokacije <- 
#   list.files(path = "/home/iva/Documents/ostalo/ARNES_hackatlon/2024_03_20/bus_id/", 
#              full.names = TRUE, recursive = TRUE)
seznam_map <- c(dnevi_mape_arg)


######### PRIPRAVA PODATKOV #########

# naredi seznam vseh datotek s postajami na linijah
postaje_za_trip_id <- lapply(postaje_mestnih_linij_range, function(x){
  return(rjson::fromJSON(file = x))
})
names(postaje_za_trip_id) <- gsub(pattern = ".json", 
                                  replacement = "", 
                                  x = basename(postaje_mestnih_linij_range))

######### FUNKCIJE #########



### filtriranje in sortiranje

#' Sortiraj časovne točke v json datoteki po času
#'
#' @param json json datoteka z lokacijskimi podatki za en avtobus za en dan
#'
#' @return sortiran json od najzgodnejše do najpoznejše lokacijske točke
sortiraj_json <- function(json){
  return(json[order(names(json))])
}

#' Fiitriranje časovnih točk, ko je avtobus aktiven (ima ime linije)
#'
#' @param json json datoteka z lokacijskimi podatki za en avtobus za en dan
#'
#' @return filltriran seznam samo s točkami, ko je avtobus bil na linijski vožnji
filt_aktivni <- function(json){
  return(json[!lapply(json, '[[', 'line_number') == ""])
}

# nova funkcija za čas - filtriranje dnevnih linij na novih datotekah

#' filtriraj uro (fitriraj datoteke za en avtobus glede na uro)
#'
#' @param json json datoteka z lokacijskimi podatki za en avtobus za en dan
#' @param zacetek ura začtka intervala
#' @param konec  ura konca intervala
#'
#' @return filltriran seznam samo s točkami, med začetkom in koncem
filt_uro <- function(json, zacetek, konec){
  ure <- lapply(strsplit(names(json), split = "_"), '[', 5)
  return(json[ure >= zacetek & ure <= konec])
}

#' filtriraj minute (fitriraj datoteke za en avtobus glede na minute)
#'
#' @param json json datoteka z lokacijskimi podatki za en avtobus za en dan
#' @param zacetek minute začtka intervala
#' @param konec  minute konca intervala
#'
#' @return filltriran seznam samo s točkami, med začetkom in koncem
filt_minute <- function(json, zacetek, konec){
  minute <- lapply(strsplit(names(json), split = "_"), '[', 6)
  return(json[minute >= zacetek & minute <= konec])
}

#' filtriraj dnevne linije (22.30–24.00 / 2.50–4.50 so nočne linije)
#'
#' @param json json datoteka z lokacijskimi podatki za en avtobus za en dan
#'
#' @return filltriran seznam samo s točkami z dnevnimi vožnjami
filt_dnevne <- function(json){
  # vmesni filter za avtobuse med 2:50 in 3:00 in 22:00 in 22:30
  prvi_filt <- filt_uro(json, 04, 23)  
  jutra <- filt_minute(prvi_filt[unlist(lapply(
    strsplit(names(prvi_filt), split = "_"), '[', 5)) == "04"], 50, 59)
  veceri <- filt_minute(prvi_filt[unlist(lapply(
    strsplit(names(prvi_filt), split = "_"), '[', 5)) == "22"], 30, 59)
  return(c(filt_uro(json, 05, 21), jutra, veceri))
}

### določanje lokacije

#' Je vrednost v razponu (na intervalu/ v rangeu)
#'
#' @param range razpon vrednosti (min, max)
#' @param vrednost vrednost 
#'
#' @return je avtobus na postaji ali ne
v_range <- function(range, vrednost) {
  return(vrednost <= max(range) & vrednost >= min(range))
}

#' Je avtobus na postaji glede na latitudo
#'
#' @param latituda lokacija avtobusa na latitudi (stopinje)
#' @param postaje vse postaje linije na kateri vozi avtobus (z lokacijami)
#'
#' @return je avtobus na postaji ali ne
na_postaji_lat <- function(latituda, postaje) {
  na_postaji <- lapply(postaje, function(x){
    return(v_range(x$latitude_range, latituda))
  })
  return(na_postaji)
} 

#' Je avtobus na postaji glede na longlitudo
#'
#' @param longituda lokacija avtobusa na longitudi (stopinje)
#' @param postaje vse postaje linije na kateri vozi avtobus (z lokacijami)
#'
#' @return je avtobus na postaji ali ne
na_postaji_lng <- function(longituda, postaje) {
  na_postaji <- lapply(postaje, function(x){
    return(v_range(x$longitude_range, longituda))
  })
  return(na_postaji)
}

#' Je avtobus na postaji
#'
#' @param json json datoteka z lokacijskimi podatki za en avtobus za en dan
#'
#' @return seznam s stop_id in trip_id za vse časovne točke, ko je avtobus
#' stal na postaji in NA za vse časovne točke, ko avtobus ni stal na postaji
na_postaji <- function(json){
  seznam_id_postaj <- lapply(json, function(x){ # zankaj po časovnih točkah
    # za časovno točko preveri, če je hitrost 0 (če ni, avtobus ne stoji)
    if (x$speed == 0){
      # poglej postaje na liniji na kateri je vozil avtobus v časovni točki
      postaje_linije <- postaje_za_trip_id[[x$trip_id]]  
      # določi, ali je avtobus trenutno na postaji
      je_na_postaji <- c(unlist(na_postaji_lat(x$latitude, postaje_linije)) 
                         & unlist(na_postaji_lng(x$longitude, postaje_linije)))
      if (sum(je_na_postaji) > 0) {
        list(stop_id = unlist(lapply(postaje_linije, 
                                     "[[", "stop_id")[je_na_postaji]), 
                                      trip_id = x$trip_id)
      } else {
        NA  # vrni NA, če avtobus ni na postaji
      }
    } else {
      NA # vrni NA, če avtobus ne stoji
    }
  })
  return(seznam_id_postaj)
}

### procesiranje lokacijskih podatkov

#' Na katerih linijah je vozil avtobus čez dan
#'
#' @param seznam_na_postaji seznam iz na_postaji
#'
#' @return seznam imen linij na katerih je v enem dnevu vozil avtobus
st_linij <- function(seznam_na_postaji){
  seznam_na_postaji_filt <- seznam_na_postaji[!is.na(seznam_na_postaji)]
  return(unlist(unique(lapply(seznam_na_postaji_filt, "[[", "trip_id"))))
}

#' pretvori seznam postaj v rle format
#'
#' @param na_postaji_po_linijah po linijah vgnezden seznam s postajami,
#' na katerih so stali avtobusi
#'
#' @return rle format (koliko točk je avtobus stal na posraji - trip_id)
#' brez končnih postaj linije
pretvori_v_rle <- function(na_postaji_po_linijah){
  rle_postaje <- lapply(seq_along(na_postaji_po_linijah), function(x){
    na_postaji_seznam <- lapply(na_postaji_po_linijah[[x]], "[[", "stop_id")
    # odstraniš prvo in zadno postajo linije -
    # tam se avtobusi najdlje zadržijo, saj čakajo na naslednjo vožnjo
    postaje_linije <- postaje_za_trip_id[[names(na_postaji_po_linijah)[[1]]]]
    prva_zadnja_postaja <- list(postaje_linije[[1]]$stop_id, 
                                postaje_linije[[length(postaje_linije)]]$stop_id)
    vmesne_postaje <- na_postaji_seznam[!na_postaji_seznam %in% prva_zadnja_postaja]
    if (length(unlist(vmesne_postaje)) > 1) {
      rle(unlist(vmesne_postaje))
    } else {
      NA
    }
  })
  return(rle_postaje)
}

#' Pretvori rle v seznam
#'
#' @param rle rle format trajanja postankov (output pretvori_v_rle)
#' seznam rle formatov za vsako linijo avtobusa
#'
#' @return seznam s številom časovnih točk na stop_id
#' koliko časovnih točk je avtobus stal na vmesni kateri postaji
pretvori_rle_seznam <- function(rle){
  trajanje_postankov <- lapply(seq_along(rle), function(x){
    # seznaam za eno linijo je lahko NA v edge case (nepopolni podatki)
    if (length(rle[[x]]) > 1){ 
      postanki_linija <- lapply(seq_along(rle[[x]]$values), function(y){
        rle[[x]]$lengths[[y]]
      })
      names(postanki_linija) <- rle[[x]]$values
      unlist(postanki_linija)
    }
  })
}

### končna analiza

#' Določi trajanje postankov avtobusa na postajah v dnevu
#'
#' @param avtobus_lokacije_json pot do json datoteke z lokacijskimi podatki za en avtobus
#'
#' @return seznam s številom časovnih točk postanka na postajah (stop_id)
analiza_avtobus <- function(avtobus_lokacije_json){
  ### preberi json datoteko
  json_file <- rjson::fromJSON(file = avtobus_lokacije_json)
  # razporedi točke v json datoteku po času - olajša kasnejšo analizo
  json_filt_sort <- sortiraj_json(json_file) 
  ### filtriraj 
  # ohrani le časovne točke, ko je avtobus na dnevni linijski vožnji
  avtobus_lokacije_filt <- filt_aktivni(json_filt_sort) # avtobus je na linijski vožnji
  avtobus_lokacije_filt_dnevne <- filt_dnevne(avtobus_lokacije_filt) # dnevna linija
  ### določi, ali je avtobus na postaji
  # iz json datoteje z lokacijami avtobusa v dnevu vzamemo line_id
  # ta line_id uporabimo, da izberemo prabilen seznam postaj iz postaje_za_trip_id
  # avtobus v vsako smer stoji na drugih postajah in lokacije postaj morajo biti temu ustrezne
  na_postaji_id <- na_postaji(avtobus_lokacije_filt_dnevne)
  # odstrani vse časovne točke, ko avtobus ni na postaji
  na_postaji_id_filt <- na_postaji_id[!is.na(na_postaji_id)]
  # če je avtobus vozil na več kot eni liniji v dnevu, 
  # razdeli časovne točke v podsezname
  if (length(na_postaji_id_filt) > 0){
    if (length(st_linij(na_postaji_id_filt)) > 1){
      # preveri, ali ja avtobus vozil na več linijah v dnevu
      trip_ids <- st_linij(na_postaji_id_filt) 
      na_postaji_trip_ids <- lapply(na_postaji_id_filt, "[[", "trip_id")
      # zankaj čez linije in izberi vse časovne točke na eni liniji v podseznam
      postaje_po_linijah <- lapply(trip_ids, function(x){
        na_postaji_id_filt[na_postaji_trip_ids %in% x]
      })
      names(postaje_po_linijah) <- trip_ids
      # če je samo ena linija vseeno naredi podseznam poimenovan s trip_id
    } else { 
      postaje_po_linijah <- list(na_postaji_id_filt)
      if (length(postaje_po_linijah) > 0) { # lahko se zgodi, da je seznam prazen
        names(postaje_po_linijah) <- lapply(na_postaji_id_filt, "[[", "trip_id")[[1]]
      } 
    }
    ### pretvorba v rle format 
    # pretvori v rle format in pri tem odstrani končne postaje linij
    # na končnih postajah avtobusi čakajo na naslednjo vožnjo,
    # torej bi njihovo upoštevanje popačio naše podatke
    postaje_rle <- pretvori_v_rle(postaje_po_linijah)
    # spremeni rle v poimenovan seznam
    trajanje_postankov <- pretvori_rle_seznam(postaje_rle)
    # iz imena datoteke dobi ime avtobusa
    unlist(trajanje_postankov)
  } else {
    NA
  }
}

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

#' Povprečen postanek avtobusa na postaji
#'
#' @param postanki_avtobusa seznam s številom časovnih točk postanka na postajah
#' (output analiza_avtobus)
#' @param seznam_postaj_id seznam identifikacijskih številk vseh mestnih postaj
#' @param st_jeder stevilo niti za vzporedno obdelavo (pazi RAM, default 1)
#'
#' @return seznam povprečnega postanka avtobusov na vsaki postaji 
#' (enota je število časovnih točk)
povprecni_postanek <- function(postanki_avtobusa, seznam_postaj_id, st_jeder = 1){
  ### trajanje postanka avtobusa na postajah (seznam po avtobusih) ###
  # seznam po avtobusih (ista postaja se pojavi večkrat)
  postanki_avtobus <- parallel::mclapply(postanki_avtobusa, function(x){
    analiza_avtobus(x)
  }, mc.cores = st_jeder)
  # poimenuj postanke
  names(postanki_avtobus) <- lapply(postanki_avtobusa, function(x){
    bus_ime <- strsplit(gsub(".json", "", basename(x)), split = "_")[[1]]
    bus_ime[length(bus_ime)]
  })
  # odstrani NAje in NULLe
  postanki_avtobus <- postanki_avtobus[!(is.na(
            lapply(postanki_avtobus, "[[", 1)) | 
            unlist(lapply(postanki_avtobus, is.null)))]
  ### trajanje postankov po postajah (seznam po postajah) ###
  # seznam postankov za vsako postajo
  # greš čez postaje in v vsakem avtobusu pogledaš trenutno postajo
  postaja_vsi_busi <- lapply(seznam_postaj_id, function(x){
    lapply(postanki_avtobus, function(y){
      y[names(y)==x]
    })
  })
  names(postaja_vsi_busi) <- seznam_postaj_id
  # odstrani vse avtobuse zbotraj postaje brez zadetkov
  postaja_vsi_busi_filt <- lapply(seq_along(postaja_vsi_busi), function(x){
    postaja_vsi_busi[[x]][unlist(lapply(postaja_vsi_busi[[x]], length)) != 0]
  })
  names(postaja_vsi_busi_filt) <- seznam_postaj_id
  # odstrani vse postaje brez zadetkov
  postaja_vsi_busi_filt <- postaja_vsi_busi_filt[lapply(postaja_vsi_busi_filt,length)>0]
  ### povprečni postanek na postajo ###
  # povprečno število zaporednih časovnih točk na postaji
  # koliko časa se v povprečju na postanku zadrži avtobus na postaji
  povprecni_postanek_seznam <- parallel::mclapply(postaja_vsi_busi_filt, function(x){
    mean(as.numeric(unlist(x)))
  }, mc.cores = st_jeder)
  return(povprecni_postanek_seznam)
}

######### ANALIZA #########

### uvoz json datotek ###

# vgnezden seznam json datotek (vsak dan posebaj) z lokacijami za vsak avtobus v enem dnevu
seznam_json_datotek <- lapply(seznam_map, function(x){
  list.files(path = x, full.names = TRUE, recursive = TRUE)
})

# imena dni
dnevi <- lapply(seznam_map, function(x){
  dan_seznam <- strsplit(x, split = "/")
  dan_ime <- strsplit(x, split = "/")[[1]][grep("2024*", strsplit(x, split = "/")[[1]])]
  dan_ime
})
names(seznam_json_datotek) <- dnevi # poimenuj vnezden seznam z dnevi


### seznam vseh stop_id (identifikacijskih številk postajališč) ###

postaje_ids <- postaje_id_st(postaje_mestnih_linij_range)

### povprecni čas postanka ###

# povprečno število zaporednih časovnih toč na postaji
# povprečno v koliko zaporednih lokacijskih datotekah
# katerikoli avtobus stoji na postaji

# izračunaj povprečen postanek za vsak dan
lapply(seq_along(seznam_json_datotek), function(x){
  povp_postanek_dan <- povprecni_postanek(seznam_json_datotek[[x]], postaje_ids, 10)
  postanki_df <- as.data.frame(cbind(povp_postanek_dan))
  colnames(postanki_df) <- c("povp_postanek")
  postanki_df$stop_id <- rownames(postanki_df)
  data.table::fwrite(postanki_df, file = 
                       paste0(out_arg, "/lpp_povp_postanek_", 
                              dnevi[[x]], ".csv"), row.names = F)
})
