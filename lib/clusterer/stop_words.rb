# -*- encoding : utf-8 -*-
#--
###Copyright (c) 2006 Surendra K Singhi <ssinghi AT kreeti DOT com>
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module Clusterer
  STOP_WORDS = ["y",
                "pero",
                "puede",
                "puedo",
                "soi",
                "alguien",
                "porque",
                "sabe",
                "nada",
                "lol",
                "wapo",
                "hay",
                "quiero",
                "muy",
                "mui",
                "pue",
                "pued",
                "tiene",
                "sin",
                "saber",
                "soy",
                "del",
                "esta",
                "esto",
                "por",
                "hacer",
                "hizo",
                "no",
                "este",
                "esta",
                "esto",
                "ese",
                "esa",
                "aquel",
                "aquella",
"queria",
"dejo",
                "nunca",
                "primero",
                "para",
                "desde",
                "tener",
                "tiene",
                "ella",
                "aqui",
                "el",
                "como",
                "en",
                "es",
"gustaria",
                "solo",
                "ultimo",
                "menos",
                "como",
                "mas",
                "nuevo",
                "ahora",
                "decir",
                "dijo",
                "a",
                "deberia",
                "desde",
                "alguno",
                "alguna",
                "algunos",
                "algunas",
                "que",
                "uno",
                "una",
                "algo",
                "algun",
                "mas",

                "eso",
                "el",
                "thei",
                "su",
                "sus",
                "entonces",
                "esos",
                "bueno",
                "buena",
                "hola",
                "todo",
                "tambien",
                "verdad",
                "donde",
                "intentar",
                "bien",
                "mucho",
                "mucha",
                "est",
                "este",
                "esta",
                "casi",
                "puedo",
                "podeis",
                "ven",
                "bien",
                "tengo",
                "tienes",
                "teneis",
                "tiene",
                "estos",
                "estas",
                "hasta",
                "url",
                "fue",
                "donde",
                "cuando",
                "quien",

                "mientras",

                "con",
                "entre",

                "www",
                "si",
                "tu",
               "nosotros",
               "vosotros",
               "ellos",

               ]

  STOP_WORDS_EN = ["and",
                "but",
                "came",
                "can",
                "cant",
                "com",
                "couldnt",
                "did",
                "didn",
                "didnt",
                "doesnt",
                "dont",
                "ever",
                "first",
                "for",
                "from",
                "have",
                "her",
                "here",
                "him",
                "how",
                "into",
                "isnt",
                "itll",
                "just",
                "last",
                "least",
                "like",
                "most",
                "new",
                "not",
                "now",
                "sai",
                "said",
                "she",
                "should",
                "since",
                "some",
                "than",
                "thi",
                "that",
                "the",
                "thei",
                "their",
                "then",
                "those",
                "told",
                "too",
                "true",
                "try",
                "until",
                "url",
                "wasnt",
                "were",
                "when",
                "who",
                "whether",
                "while",
                "will",
                "with",
                "within",
                "would",
                "www",
                "yes",
                "you",
                "youll",
               ]
end
