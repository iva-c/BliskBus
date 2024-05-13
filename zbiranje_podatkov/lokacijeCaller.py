import requests
import time
import util

def klic():
    api_url = "https://mestnipromet.cyou/api/v1/resources/buses/info"
    maksimalno_poskusov = 5
    poskus = 0  
    zakasnitev = 0.3 

    while poskus < maksimalno_poskusov:
        try:
            odziv = requests.get(api_url)
            
            if odziv.status_code == 200:
                json = odziv.json()
                return json
            else:
                raise Exception()

        except:
            poskus += 1
            if poskus < maksimalno_poskusov:
                time.sleep(zakasnitev)
            else:
                util.shrani_log('Klic lokacijeLPP - fail')
                return {}
    



