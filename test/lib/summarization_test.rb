require 'test_helper'

class SummarizationTest < ActiveSupport::TestCase
  test "extract_sentences_from_string should work" do
  end

  PAPER_KEYPHRASE_EXTRACTION = <<-END
  Compatibility of systems of linear constraints over the set of natural numbers.
  Criteria of compatibility of a system of linear Diophantine equations, strict
  inequations, and nonstrict inequations are considered. Upper bounds for
  components of a minimal set of solutions and algorithms of construction of
  minimal generating sets of solutions for all types of systems are given.
  These criteria and the corresponding algorithms for constructing a minimal
  supporting set of solutions can be used in solving all the considered types
  systems and systems of mixed types.
  END

  PAPER_KEYPHRASE_EXTRACTION_1 = <<-END
  505 Games y la desarrollado Behaviour Interactive han anunciado la llegada de un nuevo Naughty Dog que estará disponible en Xbox Live Arcade y Playstation Network a finales de este año.

  Naughty Bear: Panic in Paradise mete a los jugadores en la piel de Naughty Bear, que una vez más vuelve a ser uno de los habitantes más rechazados y marginados de todo el vecindario. Su viaje le llevara hasta unas paradisiacas vacciones de lujo en la llamada Paradise Island, pero por desgracia nadie le ha invitado a venirse de vacaciones. Armado hasta los dientes, este Oso hará pagar a todos que le den la espalda, uno por uno.

  Naughty Bear: Panic in Paradise contará con un mejorado sistema de combate, nuevo sistema para subir de nivel, equipo personaliazble y más de 30 misiones en 11 diferentes áreas.
  END

PAPER_KEYPHRASE_EXTRACTION_5 = <<-END
La fotografía que tenéis sobre estas líneas fue realizada el lunes en las oficinas centrales que VK.com, la red social más popular de Rusia, Ucrania, Bielorrusia, Kazajistán y Moldavia y una de las 50 páginas más populares de Internet de acuerdo al ránking Alexa, posee en San Petersburgo.

El diseño de este portal, que fue lanzado en septiembre de 2006, copia de manera poco disimulada el aspecto y las funcionalidades de Facebook, pero ello no ha sido óbice para que se haya convertido en un enorme éxito y haya hecho de su fundador, un joven que responde al nombre de Pavel Durov, un multimillonario con tan solo 27 años.


Tristemente, da la sensación de que no ha sabido asimilar la montaña de dinero y fama que este portal le ha reportado. La imagen que encabeza este artículo así lo atestigua. En la misma aparece junto a su vicepresidente lanzando a modo de juego avioncitos hechos con billetes de 5.000 rublos (unos 122 euros al cambio actual) a la gente que se encuentra en la calle situada bajo su despacho.



La lluvia de dinero en forma de aviones de papel provocó que una muchedumbre se agolpara en unos pocos metros cuadrados y que se produjeran peleas continuas por hacerse con el preciado dinero entre los vecinos y transeúntes que allí se encontraban mientras Durov y sus acompañantes se divertían ante el inusual y denigrante espectáculo que contemplaban desde sus privilegiados aposentos.

En un rato lanzó por la ventana unos 1.800 euros. Más tarde, a través de su cuenta de Twitter, confesó en un alarde de soberbia insultante, que, y cito textualmente, "tuvimos que parar pronto debido a que la gente se comportó como si fueran animales". Todo un personaje, como podéis ver.
END

PAPER_KEYPHRASE_EXTRACTION_2 = <<-END
Hola Mafiosos,

Tras días de hard work con trinee y V1rus_92 por fin abrimos las puertas del server Towny NO PREMIUM que tanto ansiábamos todos.

El servidor consta de los siguiente Mods:

- BuildCraft 2.2.14

- IndustrialCraft 2

- Aditional Pipes 2.1.3

- Advanced Machines 4.0

- BuildCraft & IndustrialCraft CrossOver 1.28

- Compact Solars 2.2.0.5

- Redpower 2 (completo)

Y de los siguientes plugins:

- bLift (Ascensores)

- ChestShop (Tienda)

- Crazy Login (Cuentas)

- Crazy Core (para que funcione Crazy Login ¿x'D?)

- Essentials (Comandos básicos para servers)

- iConomy (Sistema de economía)

- mcMMO (Niveles)

- MyWorlds (Distintos Mundos)

- NoLagg (Antilag)

- PermissionsEX (Sistema de Permisos)

- Player Tracker (Capo aka detector de Multicuentas)

- Stargate (Portales entre mundos)

- Towny

- Questioner (Base de Towny)

- WeatherMan (Biomas)

- WorldEdit

- Tree Assist (Treecapitator que replanta)

Estamos ansiosos de que este proyecto se expanda por la comunidad y pasemos un buen rato entre todos. Podremos empezar a dar guerra el Lunes 28 de Mayo.

La IP del servidor es:  212.227.22.192:8008

Mapa del servidor: http://212.227.22.192:8009/

TeamSpeak del servidor: 212.227.22.192:9999

Para entrar al servidor, hay que bajarse ESTE archivo y sustituirlo por tu archivo .minecraft. Para ello debes ir a inicio>ejecutar>escribir %appdata% y cambiar la carpeta del .rar por la de tu pc para que todos los mods se queden en tu ordenador. Al hacer esto, perderás las demás ip que tengas guardadas, y el single player, para no perderlas, recomendamos guardar tu carpeta .minecraft en otra parte para poder intercambiarlas.



Imágenes del spawn en proceso:
END

PAPER_KEYPHRASE_EXTRACTION_5 = <<-END
Hola ninios y ninias.

Creo que mi tarjeta grafica ha muerto. El PC se peta constantemente y al reiniciarse solo me aparece un pantallazo pixelado de lo último que ocupaba la pantalla al congelarse.

La actual es una Gforce 8600Gt...El procesador es un quad...que le puedo poner que sea de su talla, y lo mas importante, se lo puedo hacer yomismo o tengo que llamar a mi vecino de 12 años para no joder nada?
empieza poniendo la pasta que te quieres gastar, de cuanto, de que marca y de que modelo es tu fuente

La pasta, no es problema pero no quiero gastar mucho.

La fuente es una nisu de 450 W

Quería evitar cambiarla porque esto tiene mas cables que dios, pero si no hay mas remedio...


pues si no quieres cambiar la fuente y quieres ahorrarte pasta http://www.pccomponentes.com/sapphire_radeon_hd_4850_1gb_gddr3_refurbished.html

Aunque la fuente iria justisima, si quieres algo mas potente www.pccomponentes.com/sapphire_radeon_hd_6850_1gb_gddr5.html + http://www.pccomponentes.com/tacens_radix_v_650w.html


Mete la grafica al horno!



#4 yo he hecho eso del horno con la hd4650 y funciono, pero por poco tiempo, unos 5 dias. Es un metodo temporal y aun asi no tienes ninguna garantia de que vaya a funcionar.


#5 el metodo profesional es hacer reballing, que vale casi lo mismo que la grafica nueva, aun asi, con la pistola de calor si se apaña bastante bien, mucho mejor que con el horno


Yo lo del horno lo hice ya 2 veces con la 8800GTS 512, la primera vez me aguantó un par de meses, y la segunda lleva de momento 3 semanas, y mientras pueda ir tirando así mejor que mejor, que estoy peladísimo.

END


  #PAPER_KEYPHRASE_EXPECTED_SORTED = [
  #    'linear constraints',
  #    'linear diophantine equations',
  #    'natural numbers',
  #    'nonstrict inequations',
  #    'strict inequations',
  #    'upper bounds',
  #]


  PAPER_KEYPHRASE_EXPECTED_SORTED = [
      "compatibility",
      "criteria",
      "linear constraints",
      "linear diophantine equations",
      "nonstrict inequations",
      "strict inequations",
      "upper bounds",
  ]

  test "summarize_test keyphrase" do
    assert_equal(
        SummarizationTest::PAPER_KEYPHRASE_EXPECTED_SORTED,
        Summarization.summarize_text(SummarizationTest::PAPER_KEYPHRASE_EXTRACTION))
  end

  test "build_graph" do
    node_hello = Summarization::Node.new("hello")
    node_world = Summarization::Node.new("world")
    expected_graph = {"hello" => node_hello, "world" => node_world}
    assert_equal(
        expected_graph, Summarization.send(:build_graph, ["hello", "world"]))
  end

  test "node bidirectional_link" do
    node_hello = Summarization::Node.new("hello")
    node_world = Summarization::Node.new("world")
    assert_equal 0, node_world.neighbors.size
    assert_equal 0, node_hello.neighbors.size
    node_hello.bidirectional_link(node_world)
    assert_equal [node_hello], node_world.neighbors
    assert_equal [node_world], node_hello.neighbors
  end

  test "tokenize" do
    assert_equal %w(), Summarization.send(:tokenize, "")
    assert_equal %w(hello world), Summarization.send(:tokenize, "Hello World")
    assert_equal %w(hello world), Summarization.send(:tokenize, "hello.,world")
    assert_equal %w(hello-world), Summarization.send(:tokenize, "hello-world")
    assert_equal %w(hello world), Summarization.send(
        :tokenize, "hello world http://www.example.com/fuul?foo=bar")
  end

  test "tokenize_with_punctuation" do
    assert_equal %w(), Summarization.send(:tokenize_with_punctuation, "")
    assert_equal %w(hello world), Summarization.send(:tokenize_with_punctuation, "Hello World")
    assert_equal %w(hello . , world), Summarization.send(:tokenize_with_punctuation, "hello.,world")
    assert_equal %w(hello-world), Summarization.send(:tokenize_with_punctuation, "hello-world")
    assert_equal %w(hello world), Summarization.send(
        :tokenize, "hello world http://www.example.com/fuul?foo=bar")
  end


  test "add_cooccurrence_relations simple" do
    # Build input_graph
    node_hello = Summarization::Node.new("hello")
    node_world = Summarization::Node.new("world")
    input_graph = {"hello" => node_hello, "world" => node_world}

    # Build expected_graph
    node_hello = Summarization::Node.new("hello")
    node_world = Summarization::Node.new("world")
    node_hello.neighbors<< node_world
    node_world.neighbors<< node_hello
    expected_graph = {"hello" => node_hello, "world" => node_world}

    Summarization.send(
        :add_cooccurrence_relations, ["hello", "world"], input_graph, 10)

    assert_equal(expected_graph, input_graph)
  end

  test "merge_adjacent_keywords 1" do
    graph = self.setup_graph(%w(hello world bar))
    merged_kws = Summarization.send(
      :merge_adjacent_keywords, %w(hello world foo bar), 10, graph)
    assert_equal ["bar", "hello world"], merged_kws
  end

  def setup_graph(words)
    graph = {}
    words.each do |word|
      graph[word] = Summarization::Node.new(word)
      graph[word].score = 1
    end
    graph
  end

  test "merge_adjacent_keywords 2" do
    graph = self.setup_graph(%w(hello world))
    merged_kws = Summarization.send(
      :merge_adjacent_keywords, %w(hello world), 10, graph)
    assert_equal ["hello world"], merged_kws
  end

  test "merge_adjacent_keywords 3" do
    graph = self.setup_graph(%w(hello world))
    merged_kws = Summarization.send(
      :merge_adjacent_keywords, %w(one hello room world), 10, graph)
    assert_equal %w(hello world), merged_kws
  end

  test "merge_adjacent_keywords 4" do
    graph = self.setup_graph(%w(linear constraints diophantine equations))
    merged_kws = Summarization.send(
        :merge_adjacent_keywords,
        %w(linear constraints foo linear diophantine equations),
        10,
        graph)
    assert_equal ["linear constraints", "linear diophantine equations"], merged_kws
  end
end
