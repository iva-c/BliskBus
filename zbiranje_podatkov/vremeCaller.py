import requests
import xmltodict
import json
import util
import time

def klic():
    url_api = "https://meteo.arso.gov.si/uploads/probase/www/observ/surface/text/sl/observation_LJUBL-ANA_BEZIGRAD_latest.xml"
    maksimalno_poskusov = 10
    poskus = 0
    zakasnitev = 5

    while poskus < maksimalno_poskusov:
        try:
            odziv = requests.get(url_api).text
            podatki_json = xmltodict.parse(odziv)
            return podatki_json['data']['metData']

        except:
            poskus += 1
            if poskus < maksimalno_poskusov:
                time.sleep(zakasnitev)
            else:
                util.shrani_log('Klic vreme - neuspešno')


