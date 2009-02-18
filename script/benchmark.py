#!/usr/bin/env python
import re
import os
# CONFIG
urls = ['/',
  '/apuestas',
  '/apuestas/show/73',
  '/colabora',
  '/columnas',
  '/columnas/show/55',
  '/competiciones',
  '/competiciones/show/5',
  '/competiciones/show/5/ranking',
  '/competiciones/show/5/participantes',
  '/competiciones/show/5/reglas',
  '/competiciones/partida/45',
  '/competiciones/participante/13',
  '/competiciones/participante/58',
  '/descargas',
  '/descargas/967',
  '/descargas/1028',
  '/descargas/show/10',
  '/encuestas',
  '/encuestas/show/79',
  '/entrevistas',
  '/entrevistas/show/39',
  '/eventos',
  '/eventos/show/850',
  '/facciones',
  '/facciones/show/1',
  '/facciones/show/18/miembros',
  '/foros',
  '/foros/forum/845',
  '/foros/forum/849',
  '/foros/topic/12413',
  '/imagenes',
  '/imagenes/773',
  '/imagenes/show/267',
  '/imagenes/716',
  '/imagenes/potds',
  '/miembros',
  '/miembros/dharana',
  '/miembros/dharana/noticias',
  '/noticias',
  '/noticias/show/21581',
  '/noticias_eventos/show/354',
  '/offtopics',
  '/offtopics/show/289',
  '/portales',
  '/resumenes',
  '/resumenes/20060703',
  '/site/acercade',
  '/site/banners',
  '/site/faq',
  '/site/netiquette',
  '/site/online',
  '/site/show_smileys',
  '/site/staff',
  '/site/trastornos',
  '/tutoriales',
  '/tutoriales/109',
  '/tutoriales/show/6'
  ]

# END CONFIG

if __name__ == '__main__':
    p = re.compile('Requests per second:    ([0-9.]+) ')

    for url in urls:
      pipe = os.popen('/usr/local/hosting/bin/ab -n50 http://192.168.0.100:3000%s' % url)
      output = pipe.read().replace("\n", ' ')
      pipe.close()
      print url.ljust(50, ' '),
      # print output
      print p.search(output).group(1)
