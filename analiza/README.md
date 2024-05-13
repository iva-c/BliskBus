# Analiza podatkov

Skripte uporabljene za analizo podatkov o lokacijah avtobusov LPP. Zaradi obsežnosti zbranih podatkov, sva najzahtevnejši del analize izvedla na superračunalniški gruči Arnes. Skripte so predsavljene v vrsnem redu, kot si sledijo v izvajanju analize. 	

## bliskbus_priprava_podatkov_cmd.R
Priprava podatkov za analizo. Izberi samo mestne postaje, določi velike in majhne postaje in temu promerno razpon latitude in longitude v kateri se mora nahajati avtobus, da velja, da stoji na postaji.  

Input:  
- trip_ids.json (slovar med "trip_id" in "line_num")
- station-details.json (podatkih o LPP postajah)
- /postajalisca_of_tripid/ (json s postajami na vsaki liniji v vsako smer posebaj poimenovan s pripadajočim trip_id)

Output:  
- json datoteke iz /postajalisca_of_tripid/ z dodanim latitude in longitude razponov, v katerem je avtobus na postaji. 	

Okolje: bliskbus_R_sing.def  


## lokacije_za_bus_pretvorba.py 
Pretvorba json datotek z lokacijami vseh avtobusov v eni časovni točki, v json ddatoteke s vsemi časovnimi točkami avtobusa v enem dnevu. Pretvorba zaradi lažje nadaljne analize, zaradi količine podatkov izvedena na HPC Arnes. 	

Input: 
- seznam poti do map z datotekami lokacij avtobusov v enem dnevu (objavljene na https://zenodo.org/records/11187068)	

Output:   
- json datoteke za vsak avtobus posebaj z lokacijami čez cel dan

Okolje: bliskbus_python_sing.def 


## bliskbus_analiza_podatkov_cmd.R
Analiza najbolj obremenjenih postaj na dnevnih linijah ob delovnikih. Filtriranje dnevnih linij po času, filtriranje aktivnih linij (bus ima ime linije in prižgan motor), določanje, ali je avtobus na postaji (je znotraj določenega polmera okrog postaje in ima hitrost 0), pretvorba v rle, izračun povprečenega postanka avtobusa na vsaki postaji v enem dnevu. 

Input: 
- seznam datotek z lokacijami avtobusov v enem dnevu generiranih s lokacije_za_bus_pretvorba.py 
- /postajalisca_of_tripid/ (json s postajami na vsaki liniji v vsako smer posebaj poimenovan s pripadajočim trip_id)

Output:  
- csvji s povprečnim trajanjem postanka avtobusov (enota je število časovnih točk, * 3s za pretvorbo v čas) na vsaki postaji (stop_id)

Okolje: bliskbus_R_sing.def  

## bliskbus_analiza_rezultatov_gh.R
Dodatna filtriranja in povprečenje časov postankov v vseh delovnih dnevih. 

Input: 
- csvji s povprečnim trajanjem postanka avtobusov (bliskbus_analiza_podatkov_cmd.R) za delavnike
- /postajalisca_of_tripid/ (json s postajami na vsaki liniji v vsako smer posebaj poimenovan s pripadajočim trip_id)

Output:  
- csv s povprečnim trajanjem postanka avtobusov ob delavnikih za postaje mestnih linij

Okolje: bliskbus_R_sing.def  




##