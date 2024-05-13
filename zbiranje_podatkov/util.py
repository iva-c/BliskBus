import datetime
import os
import json

# Vrne trenuten cas v obliki leto_mesec_dan_ura_minuta_sekunda
def pridobi_cas():
    trenuten_cas = datetime.datetime.now()
    leto = trenuten_cas.year
    mesec = f"{trenuten_cas.month:02d}"
    dan = f"{trenuten_cas.day:02d}"
    ura = f"{trenuten_cas.hour:02d}"
    minuta = f"{trenuten_cas.minute:02d}"
    sekunda = f"{trenuten_cas.second:02d}"

    return f"{leto}_{mesec}_{dan}_{ura}_{minuta}_{sekunda}"

def shrani_json(json_podatki, pot, predpona, sortirajVMapo = False):
    trenuten_cas = datetime.datetime.now()
    leto = trenuten_cas.year
    mesec = f"{trenuten_cas.month:02d}"
    dan = f"{trenuten_cas.day:02d}"

    mapa = f"{leto}_{mesec}_{dan}/" if sortirajVMapo else ""

    ime_datoteke = f"{predpona}_{pridobi_cas()}.json"

    try: 
        os.makedirs(os.path.join(pot, mapa), exist_ok=True) # ce danasnja mapa se ne obstaja, usvari novo
        with open(pot+mapa+ime_datoteke, 'w') as f:
            json.dump(json_podatki, f)
        
        print(f"{pridobi_cas()} --- zapis {predpona} - SUCCESS") # izpise ce zapis lokacij uspe
    except Exception as e: 
        save_log(f"{pridobi_cas()} --- zapis {predpona}{e} - FAIL") #zapise neuspeli poiskus zapisa lokacije

    return 



def schedule_task(task, every=False, at=False):
    nazadnje_zagnano = [datetime.datetime.min]
    
    def parse_cas(cas_str):
        danes = datetime.datetime.now().date()
        ure, minute = map(int, cas_str.split(':'))
        return datetime.datetime.combine(danes, datetime.time(hour=ure, minute=minute))
    
    def preveri_in_zazeni():
        nonlocal nazadnje_zagnano
        trenuten_cas = datetime.datetime.now()
        
        if every:
            if (trenuten_cas - nazadnje_zagnano[0]).total_seconds() >= every:
                task()
                nazadnje_zagnano[0] = trenuten_cas

        elif at:
            target_cas = parse_cas(at)
            if trenuten_cas >= target_cas and nazadnje_zagnano[0] < target_cas:
                task()
                nazadnje_zagnano[0] = trenuten_cas
                
    return preveri_in_zazeni


def save_log(sporocilo):
    with open('./log', 'a') as f:
        log = f"{pridobi_cas()}   -----    {sporocilo}"
        print(log)
        f.write(log + '\n')