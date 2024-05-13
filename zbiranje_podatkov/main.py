import time
import util
import lokacijeCaller
import vremeCaller

lokacijeLPP = util.schedule_task(lambda: util.shrani_json(lokacijeCaller.klic(), './lokacijeLPP/', 'lpp', True), every=3)
vreme = util.schedule_task(lambda: util.shrani_json(vremeCaller.klic(), './vreme/', 'vreme'), at="14:30")

# Vsako stotinko sekunde preveri ali je ze cas za ponoven klic
while True:
  lokacijeLPP();
  vreme();

  time.sleep(0.01)
