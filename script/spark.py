#!/usr/local/hosting/bin/python2.4 -u

# __author__ = "Joe Gregorio (joe@bitworking.org)"

import sys
import os
import time

import Image, ImageDraw, ImageFont
import StringIO
import urllib

def plot_sparkline_discrete(results, args, longlines=False):
    """The source data is a list of values between
      0 and 100 (or 'limits' if given). Values greater than 95 
      (or 'upper' if given) are displayed in red, otherwise 
      they are displayed in green"""
    width = int(args.get('width', '2'))
    height = int(args.get('height', '14'))
    upper = int(args.get('upper', '50'))
    below_color = args.get('below-color', 'gray')
    above_color = args.get('above-color', 'red')
    zero_color = args.get('zero-color', above_color)
    gap = 4
    if longlines:
        gap = 0
    im = Image.new("RGBA", (len(results)*width-1, height), args.get('bgcolor', '#f2f2f2')) 
    (dmin, dmax) = [int(x) for x in args.get('limits', '0,100').split(',')]
    if dmax < dmin:
        dmax = dmin
    zero = im.size[1] - 1
    if dmin < 0 and dmax > 0:
        zero = im.size[1] - (0 - dmin) / (float(dmax - dmin + 1) / (height - gap))
    draw = ImageDraw.Draw(im)
    for (r, i) in zip(results, range(0, len(results)*width, width)):
        color = (r >= upper) and above_color or below_color
        if r == 0:
            color = zero_color
        if r < 0:
            y_coord = im.size[1] - (r - dmin) / (float(dmax - dmin + 1) / (height - gap))
        else:
            y_coord = im.size[1] - (r - dmin) / (float(dmax - dmin + 1) / (height - gap))
        if longlines:
            draw.rectangle((i, zero, i+width-2, y_coord), fill=color)
        else:
            draw.rectangle((i, y_coord - gap, i+width-2, y_coord), fill=color)
    del draw                                                      
    f = StringIO.StringIO()
    
    im = im.convert('RGB').convert('P', palette=Image.ADAPTIVE)

    # buscamos el negro para hacerlo transparente
    for i in range(len(im.getpalette()) / 3):
        r = im.getpalette()[i*3]
        g = im.getpalette()[i*3+1]
        b = im.getpalette()[i*3+2]
        print r, g, b
        if (r, g, b) == (0, 0, 0):
            break

    im.save(f, "PNG", transparency=i)

    return f.getvalue()

def plot_sparkline_discrete_2sides(results, args, longlines=False):
    """The source data is a list of values between
      0 and 100 (or 'limits' if given). Values greater than 95 
      (or 'upper' if given) are displayed in red, otherwise 
      they are displayed in green"""
    width = int(args.get('width', '2'))
    height = int(args.get('height', '14'))
    upper = int(args.get('upper', '50'))
    below_color = args.get('below-color', 'gray')
    above_color = args.get('above-color', 'red')
    gap = 4
    if longlines:
        gap = 0
    im = Image.new("RGB", (len(results)*width-1, height), args.get('bgcolor', '#f2f2f2')) 
    (dmin, dmax) = [int(x) for x in args.get('limits', '0,100').split(',')]
    if dmax < dmin:
        dmax = dmin
    zero = im.size[1] - 1
    if dmin < 0 and dmax > 0:
        zero = im.size[1] - (0 - dmin) / (float(dmax - dmin + 1) / (height - gap))
    draw = ImageDraw.Draw(im)
    for (r, i) in zip(results, range(0, len(results)*width, width)):
        color = (r >= upper) and above_color or below_color
        if r < 0:
            y_coord = im.size[1] - (r - dmin) / (float(dmax - dmin + 1) / (height - gap))
        else:
            y_coord = im.size[1] - (r - dmin) / (float(dmax - dmin + 1) / (height - gap))
        if longlines:
            draw.rectangle((i, zero, i+width-2, y_coord), fill=color)
        else:
            draw.rectangle((i, y_coord - gap, i+width-2, y_coord), fill=color)
    del draw                                                      
    f = StringIO.StringIO()
    im.save(f, "PNG")
    return f.getvalue()

def plot_sparkline_smooth(results, args):
   step = int(args.get('step', '2'))
   height = int(args.get('height', '20'))
   width_base = (len(results)-1)*step
   width = width_base + len(str(max(results)))*8
   (dmin, dmax) = [int(x) for x in args.get('limits', '0,100').split(',')]
   im = Image.new("RGB", (width, height), args.get('bgcolor', '#f2f2f2'))
   draw = ImageDraw.Draw(im)
   coords = zip(range(1,len(results)*step+1, step), [height - 3  - (y-dmin)/(float(dmax - dmin +1)/(height-4)) for y in results])
   draw.line(coords, fill="#888888")
   min_color = args.get('min-color', '#0000FF')
   max_color = args.get('max-color', '#00FF00')
   last_color = args.get('last-color', '#FF0000')
   has_min = args.get('min-m', 'false')
   has_max = args.get('max-m', 'false')
   has_last = args.get('last-m', 'false')
   if has_min == 'true':
      min_pt = coords[results.index(min(results))]
      draw.rectangle([min_pt[0]-1, min_pt[1]-1, min_pt[0]+1, min_pt[1]+1], fill=min_color)
   if has_max == 'true':
      max_pt = coords[results.index(max(results))]
      draw.rectangle([max_pt[0]-1, max_pt[1]-1, max_pt[0]+1, max_pt[1]+1], fill=max_color)
   if has_last == 'true':
      end = coords[-1]
      draw.rectangle([end[0]-1, end[1]-1, end[0]+1, end[1]+1], fill=last_color)
    
   draw.text([width_base + 4, 1], str(max(results)), font=ImageFont.truetype('04b03.ttf', 8), fill=(0,0,0,0))
   draw.text([width_base + 4, 11], str(min(results)), font=ImageFont.truetype('04b03.ttf', 8), fill=(0,0,0,0))
   
   del draw
   f = StringIO.StringIO()
   im.save(f, "PNG")
   return f.getvalue()

def plot_error(results, args):
   im = Image.new("RGB", (40, 15), 'white')
   draw = ImageDraw.Draw(im)
   draw.line((0, 0) + im.size, fill="red")
   draw.line((0, im.size[1], im.size[0], 0), fill="red")
   del draw                                                      
   f = StringIO.StringIO()
   im.save(f, "PNG")
   return f.getvalue()

plot_types = {'discrete': plot_sparkline_discrete, 
               'impulse': lambda data, args: plot_sparkline_discrete(data, args, True),
         'impulse2sides': lambda data, args: plot_sparkline_discrete_2sides(data, args, True), 
                'smooth': plot_sparkline_smooth,
                 'error': plot_error
    }


import math

def percentile(N, percent, key=lambda x:x):
    """
    Find the percentile of a list of values.

    @parameter N - is a list of values. Note N MUST BE already sorted.
    @parameter percent - a float value from 0.0 to 1.0.
    @parameter key - optional key function to compute value from each element of N.

    @return - the percentile of the values
    """
    if not N:
        return None
    k = (len(N)-1) * percent
    f = math.floor(k)
    c = math.ceil(k)
    if f == c:
        return key(N[int(k)])
    d0 = key(N[int(f)]) * (c-k)
    d1 = key(N[int(c)]) * (k-f)
    return d0+d1



if __name__ == '__main__':
    # los valores estan como primer argumento
    #data = sys.argv[1]
    
    # data = [0, 15, 35, 0, 20, 25, 22, 20]
    data = [int(d) for d in sys.argv[2].split(",") if d]
    
    # modes = {'faction_activity': ('impulse', {'width': 4, 
    #                                          'limits': '%i,%i' % (min(data), max(data)), 
    #                                          'upper': percentile(data2, 0.95), 
    #                                          'above-color': '#ee0112', 
    #                                          'below-color': '#989898'}),
    #     }
    dst_file = sys.argv[3]
    # dst_file = "C:\\tmpo.png"
    #type = modes[sys.argv[1]][0] # 'impulse'
    # args = modes[sys.argv[1]][1]
    
    data2 = list(data)
    data2.sort()
    # upper =  # TODO calcular
    if sys.argv[1] == 'faction_activity':
        type = 'impulse'
        upper = percentile(data2, 0.95) # TODO calcular
        if max(data) == 0 or min(data) == 0:
            upper = 100000
    
        min = min(data)
        if min > 0:
            min = min - 1
        args = {'width': 4, 
                'limits': '%i,%i' % (min, max(data)), 
                'upper': upper, 
                'above-color': '#ee0112', 
                'below-color': '#989898'}
    elif sys.argv[1] == 'bet_rate':
        # Estos datos necesitan ser normalizados ya que vamos a comparar unos con otros
        type = 'impulse'
        
        args = {'width': 3,
                'height': 20, 
                'limits': '%i,%i' % (min(data), max(data)), 
                'upper': 0, 
                'bgcolor': (0,0,0,0),
                'above-color': '#06bc01',
                'zero-color': '#aaaaaa', 
                'below-color': '#f6001d'}
    elif sys.argv[1] == 'winlose':
        # Estos datos necesitan ser normalizados ya que vamos a comparar unos con otros
        type = 'impulse'
        
        args = {'width': 4,
                'height': 22, 
                'limits': '%i,%i' % (min(data), max(data)), 
                'upper': 0, 
                'bgcolor': (0,0,0,0),
                'above-color': '#06bc01',
                'zero-color': '#000000', 
                'below-color': '#f6001d'}
    elif sys.argv[1] == 'metric':
        # Estos datos necesitan ser normalizados ya que vamos a comparar unos con otros
        type = 'smooth'
        
        args = {'step': 2,
                'height': 20, 
                'limits': '%i,%i' % (min(data), max(data)), 
                'upper': 0, 
                'bgcolor': (255,255,255,255),
                'above-color': '#06bc01',
                'zero-color': '#aaaaaa', 
                'below-color': '#f6001d'}
     
     
    image_data = plot_types[type](data, args)
    
    open(dst_file, 'wb+').write(image_data)