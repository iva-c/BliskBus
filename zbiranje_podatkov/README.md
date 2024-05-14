# zbiranje podatkov

Skripte za zbiranje podatkov za analizo. Za poganjanje se je uporabljajo isto okolje kot za grafe (conda yml datoteka je v /BliskBus/grafike/environment.yml)

## lokacijeCaller.py
Zbiraje lokacij iz API https://mestnipromet.cyou/api/v1/resources/buses/info

## vremeCaller.py
Zbiranje dnevnih podatkov o vremenu iz ARSO (padavine bi lahko vplivale na zamude)

## main.py
Sceduler za dnevno pobiranje vremenskih podatkov in zbiranje podatkov o lokacijah avtobusiv vsake 3 sekunde

## util.py
Pomožne funkcije (shrani json, dobi trenuten čas, schedulaj task)

