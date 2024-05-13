# BliskBus

Projekt za Arnesov HackathON

Avtorja: Iva Černoša in Neo Xander Kirbiš

> [!NOTE]
> This is a project for a Slovene hackathon. The goal of the project was to design fast bus lines in Ljubljana, Slovenia, based on continiously collected live bus locations. 


Hitre avtobusne linije Ljubljanskega potniškega prometa

Analiza prosto dostopnih podatkov o lokacijah avtobusov Ljubljanskega potniškega prometa (LPP) s ciljem določitve najbolj obremenjenih postaj mestnih avtobusov in iz njih načrtovati hitre linije avtobusov, ki bi povezovale postaje z največjo uporabo ter preskočile preostale postaje. Takšne linije bi skrajšale potovalni čas Ljubljanskega mestnega javnega prevoza in povečale število povezav, ki so na voljo, ter tako odgovorile na glavna vzroka za neuporabo javnega prevoza.

Več kot en mesec sva vsake 3 sekunde preko API nabirala podatke o lokacijah vseh avtobusov LPP. S pomočjo datotek s postajališči vsseh linije v vsako smer sva določila, koliko časa se v povprečju avtobusi dnevnih linij med delavniki zadržijo na posamezni postaji. To sva uporabila za načrtovanje hitrih avtobusnih linij, ki se ustavljajo le na najnolj obremenjenih postajališčih.


> [!TIP]
> Podrobnejše informacije o skriptah so v README datotekah v podmapah

## analiza

R in Python skripte uporabljene za analizo lokacijskih podatkov (na HPCjih) in določitev najbolj obremenjenih postaj mestnih avtobusov. Mapa vsebuje tudi Singularity deffeniton datoteki uporabljeni za zaganjanje skript. 	

## grafike

Prikaz obremenjenosti LPP postaj na zemljevidu Ljubljane (s folium).	

## podatki

Manjše datoteke uporabljene za analizo (podatki o vseh postajah in o vseh linijah).	

## zbiranje_podatkov

Skripte za pobiranje lokacij avtobusov iz https://mestnipromet.cyou/api/v1/resources/buses/info preko API.	



