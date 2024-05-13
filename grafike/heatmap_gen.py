import folium
import json
import csv


#Vrne maximalen povprecen postanek na postaji
def get_max_postanek():
    with open('lpp_povp_postanek_delavnik_stop_id_mestne.csv') as f:
        csvreader = csv.reader(f)
        max = 0
        for index, row in enumerate(csvreader):
            if (index == 0): continue #Naslovna vrstica se ne prebere
            try:
                st = float(row[1]) #spremeni prebran postanek v dec. stevilo
                if (max < st): max = st # ce je trenutno prebran postanek vecji od prejsnjega maxa -> nov max = postanek
            except: #ce je tezava pri branju vrstice, se ignorira.
                max = max
        return max
    
# Vrne velikost kroga na mapi na podlagi vnesene popularnosti - povp. dolzine postanka
def calculate_circle_size(popularity):
    return popularity * 1000 + 10 

# Vrne barvo kroga na podlagi vnesene popularnost
def get_color(popularity):
    green_amount = (1 - popularity) * 255
    red_amount = min(popularity * 255 * 6, 255)  
    return f'#{int(red_amount):02x}{int(green_amount):02x}00'

# Iz datoteke lpp_povp_postanek_delavnik_stop_id_mestne.csv prebere povprecen postanek glede na podan id postaje
def get_popularnost(ref_id):
    with open('lpp_povp_postanek_delavnik_stop_id_mestne.csv') as f:
        csvreader = csv.reader(f)

        for index, row in enumerate(csvreader):
            #gre skozi vse vrstie v lpp_povp_postanek_delavnik_.... in najde tisti vrstico, ki govori o podanem ref_id
            if (index) == 0: continue
            if (row[0] == ref_id): 
                try:
                    povp_postanek = float(row[1])
                    return povp_postanek / max_postanek #normalizacija dolzine postanka (vrednost od 0 - 1)
                except:
                    return 0.0
    # Ce za podan ref_id ni podatka o povp postanku, vrne 0
    return 0.0 



postaje = []
max_postanek = get_max_postanek()

with open('./postaje.json', 'r') as postaje_f:
    postaje = json.load(postaje_f)['data'] #prebere vse ljubljanske postaje iz postaje.json
    

# inicializira knjiznico za prikazovanje zemljevida Folium z zacetnimi koordinatami in povecavo
m = folium.Map(location=[46.05322222, 14.50394444], zoom_start=10)

# za vsako postajo prebrano iz postaje.json se izrise krog
for postaja in postaje:
    popularnost = get_popularnost(postaja['ref_id'])
    folium.Circle(
        location=(postaja['latitude'], postaja['longitude']),
        radius=calculate_circle_size(popularnost), #izracuna velikost kroga
        color=get_color(popularnost), #izracuna barvo kroga
        fill=True,
        fill_color=get_color(popularnost),
        tooltip=postaja['name'] # nastavi vsebino vsebnika, ki se prikaze na dotiku z misko, na ime postaje
    ).add_to(m)

m.save('./postaje.html') #shrani interaktivno mapo v postaje.html

