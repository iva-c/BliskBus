#!/usr/bin/env python

import argparse
import json
from collections import defaultdict
from pathlib import Path
import glob
import os

def uvozi_datoteke(pot_mape:list) -> list: 
    ''' Naredi seznam json datotek lokacij vseh avtobusov ob določenem času v mapi.

    Args:
        pot_mape (list): seznam poti map z datotekami z lokacijami vseh avtobusov v enem dnevu

    Returns:
        list: vgnezden seznam lokacijskih json datotek za vsak dan

    '''
    lok_dat = []
    for pot in pot_mape:
        dan = glob.glob(pot + "*.json")
        lok_dat.append(dan)
    return(lok_dat)

def podatki_za_bus(datoteke_dan:list) -> dict:
    ''' Preuredi podatke iz lokacij vseh avtobusov ob določenem času na vse lokacije posameznega avtobusa v dnevu.

    Args:
        datoteke_dan (list): seznam poti do datotek z lokacijami vseh avtobusov v enem dnevu

    Returns:
        dict: slovar lokacij posameznih avtobusov v enem dnevu

    '''
    posamezni_busi = defaultdict(lambda: defaultdict(dict))
    for dat in datoteke_dan:
        with open(dat) as f:
            bus_lokacije = json.load(f)
            for bus in bus_lokacije["data"]:
                posamezni_busi[bus["bus_id"]][os.path.basename(dat).split(".")[0].split("_",1)[1]] = bus
    return(posamezni_busi)

def shrani_json(posamezni_bus:dict, pot_not:list, pot_ven:str):
    ''' Shrani podatke o lokacijah posameznega avtobusa v dnevu kot json.

    Args:
        posamezni_bus (dict): slovar lokacij posameznih avtobusov v enem dnevu (output podatki_za_bus)
        pot_not (list): seznam poti, kjer so skranjene json datoteke z lokacijami
        pot_ven (str): pot, kjer bodo skranjene json datoteke

    Returns:
        json: json datoteke z lokacijami posameznih avtobusov v dnevu v pot_ven/

    '''
    for key, value in posamezni_bus.items():
        with open(pot_ven + "lpp_" + pot_not[0].split("/")[-2] + "_" + key + ".json", 'w') as f:
            json.dump(posamezni_bus[key], f)

def main():
    ''' Pretvori datoteke lokacij vseh avtobusov ob določenem času iz API 
    v datoteke z lokacijami posameznega avtobusa v enem dnevu.
    Datoteke shrani v podmamapo /bus_id/ v mapi za posamezni dan.

    '''    
    # uvozi argumente iz konzole
    parser = argparse.ArgumentParser(description='Pretvori lokacijske podatke v datoteke za vsak avtobus posebaj.')
    # uvozi poti map kot seznam
    parser.add_argument('-p','--path', nargs='+', help='Poti do dnevnih map z lokacijskimi datotekami', required=True)
    parser.add_argument('-o','--out', help='Pot do mape za shranjevanje ustvarjenih datotek', required=True)
    args = parser.parse_args()
    poti = args.path
    ven = args.out
    # preveri, ali so poti veljavne
    for pot in poti:
        if not Path(pot).exists():
            print(pot + "ne obstaja")
            raise SystemExit(1)
    # pretvorba datotek
    seznam_lokacije = uvozi_datoteke(poti)  # uvozi poti vseh json datotek v mapah
    # za vsak dan posebaj pretvori datoteke v lokacije posameznega avtobusa
    for dan in seznam_lokacije:
        dan_busi = podatki_za_bus(dan)  # preuredi v jsone za bus
        # naredi podmapo bus_id v mapi z lokacijskimi datotekami in shrani lokacije avtobusov tja
        os.mkdir(poti[i] + "/bus_id/")
        shrani_json(dan_busi, dan, ven) # shrani jsone za posamezni avtobus

if __name__ == '__main__':
  rc = main()