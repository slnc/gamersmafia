module Skins
  module TexturesGenerators
    class CssPosition
      def initialize(foo)
        
      end
    end
    def self.load_generator(generator_name, user_data)
    end
    
    def self.texturable_things
      ['body', '.container', '.module', '#ccontent .module', '.module .mtitle']
    end
    
    CSS_PRIORITIES = HashWithIndifferentAccess.new({'body' => 1,
      '.container' => 10,
      '.module' => 20,
      '.module .mtitle' => 40,
      '#ccontent .module' => 50})
    
    def self.get_priority_for_element(element)
      CSS_PRIORITIES.fetch(element.gsub("'", ''))
    end
    
    class AbstractTexture
      
      def self.valid(range)
        @@range = range
      end
      
      def css_read_and_replace(texture, hash)
        # TODO esto va bien aquí?
        css_tpl = File.open("#{texture.dir}/style.css").read
        hash.each do |k,v|
          raise "#{k} not found in textures's style.css" unless hash.keys.include?(k)
          css_tpl.gsub!("${#{k}}", v)
        end
        css_tpl
      end
      
      def process(texture, user_options)
        _process(texture, user_options)
        # Devuelve el código css listo para inyectarse en la skin así como 
        # la lista de imágenes adjuntas generadas para este proceso.
        # Es responsabilidad del que le llame mover esas imágenes así como reescribir las rutas a las imágenes para que funcionen correctamente
      end
    end
    
    # Imagen subida por el usuario
    class STCustomBackgroundRepeat < AbstractTexture
      
      USER_OPTIONS = {"Imagen" => nil} # opciones configurables
      def _process(texture, user_options)
        FileUtils.cp(options["Imagen"], newtmpfile)
        css_read_and_replace({:file => File.basename(newtmpfile)})
      end
      # los archivos de cada textura definen backgroundRepeat y backgroundPosition
      # uno puede ser backgroundRepeat repeat y backgroundPosition top left
      # el otro puede ser backgroundRepeat none
    end
    
    class STCustomBackgroundNoRepeat < AbstractTexture
      
      USER_OPTIONS = {"Imagen" => nil, "Posición" => CssPosition.new('top left')} # opciones configurables
      # los archivos de cada textura definen backgroundRepeat y backgroundPosition
      # uno puede ser backgroundRepeat repeat y backgroundPosition top left
      # el otro puede ser backgroundRepeat none
    end
    
    class HueMorpher < AbstractTexture
      # Copia las variaciones de hue entre la imagen de referencia y el color dado
      USER_OPTIONS = {:hue => Hue.new(60)} # TODO pick a better default
      def _process(texture, user_options)
        tmp_dir = "#{Dir.tmpdir}/#{Kernel.rand.to_s}"
        FileUtils.mkdir(tmp_dir)
        newtmpfile = "#{tmp_dir}/file.png"
        
        # Modificamos los colores de las patterns
        im = Cms::read_image("#{texture.dir}/file.png")
        raise "image #{texture.dir}/file.png is not pseudoclass" unless im.colors
        #im.compress_colormap!
        user_options_color = Skins::convert_strings_to_attribute_wrappers(USER_OPTIONS, user_options)
        base_hue = texture.texture_attrs[:base_hue].to_i / 360.0 
        huoc = user_options_color[:hue].value / 360.0 #, suoc, vuoc =  Skins::ColorGenerators::rgb_to_hsv(*Skins::ColorGenerators::rgbhex_to_rgb(user_options_color.to_s))
        # puts "User Color: #{user_options_color.to_s} hsv(#{huoc}, #{suoc}, #{vuoc}) h360: #{huoc*360}deg"
        #puts huoc, suoc, vuoc
        im.colors.times do |i|
          color = Magick::Pixel.from_color(im.colormap(i))
          # cogemos el hue y se lo aplicamos al color
          h, s, v = Skins::ColorGenerators::rgb_to_hsv(color.red/255.0, color.green/255.0, color.blue/255.0)
          
          cur_huoc = (h < base_hue) ? (huoc - (base_hue - h)) : (huoc + (h - base_hue))
          # puts "cur huoc: (#{h} < #{base_hue}) ? (#{huoc} - (#{base_hue} - #{h})) : (#{huoc} + (#{h} - #{base_hue}))"
          cur_huoc = cur_huoc - 1 if cur_huoc > 1.0 # TODO repetido
          cur_huoc = 1 - cur_huoc if cur_huoc < 0.0 # TODO repetido
          # puts "#{cur_huoc}, #{suoc}, #{newv}"
          newcolor = Skins::ColorGenerators::hsv_to_rgb(cur_huoc, s, v) # (v + vuoc) / 2)
          im.colormap(i, "rgb(#{(newcolor[0]*255).to_i}, #{(newcolor[1]*255).to_i}, #{(newcolor[2]*255).to_i})")
          
          #puts "\nPROCESANDO COLOR DE PALETA #{i}"
          #puts "original RGB(#{color.red} #{color.green} #{color.blue}) HSV(#{h} #{s} #{v})"
          #puts "nuevo    RGB(#{(newcolor[0]*255).to_i}, #{(newcolor[1]*255).to_i}, #{(newcolor[2]*255).to_i}) HSV(#{huoc} #{s} #{(v + vuoc) / 2})"
          #puts "color viejo: #{color}"
          #puts "color nuevo: #{(newcolor[0]*255).to_i}, #{(newcolor[1]*255).to_i}, #{(newcolor[2]*255).to_i}"
        end
        im.write(newtmpfile)
        css = css_read_and_replace(texture, {:element_selector => user_options[:element_selector].gsub("'", '')})
        [css, [newtmpfile]]
        # TODO quién borra ese dir temporal?
      end
    end
    
    class GrayscalePattern < AbstractTexture
      USER_OPTIONS = {:color => RgbColor.new('aa0000')} #, :darkness => Percent.new(85)}
      # USER_OPTIONS = { "base_color" => nil }
      # TEXTURE_ATTRS = [:color1, :color2]
      
      def _process(texture, user_options)
        tmp_dir = "#{Dir.tmpdir}/#{Kernel.rand.to_s}"
        FileUtils.mkdir(tmp_dir)
        newtmpfile = "#{tmp_dir}/file.png"
        
        # Modificamos los colores de las patterns
        im = Cms::read_image("#{texture.dir}/file.png")
        raise "image #{texture.dir}/file.png is not pseudoclass" unless im.colors
        #im.compress_colormap!
        user_options_color = Skins::convert_strings_to_attribute_wrappers(USER_OPTIONS, user_options)[:color]
        # necesito el hue del color que tenga
        # necesito convertir el color rgb a hsv
        # pero antes tengo que convertir los valores rgb enteros a floats
        
        strength = texture.texture_attrs[:strength]
        color_dispersion = texture.texture_attrs[:color_dispersion]
        color_dispersion = 0 if color_dispersion.nil?
        
        
        huoc, suoc, vuoc =  Skins::ColorGenerators::rgb_to_hsv(*Skins::ColorGenerators::rgbhex_to_rgb(user_options_color.to_s))
        #puts "User Color: #{user_options_color.to_s} hsv(#{huoc}, #{suoc}, #{vuoc}) h360: #{huoc*360}deg"
        
        im.colors.times do |i|
          color = Magick::Pixel.from_color(im.colormap(i))
          # cogemos el hue y se lo aplicamos al color
          h, s, v = Skins::ColorGenerators::rgb_to_hsv(color.red/255.0, color.green/255.0, color.blue/255.0)
          d = (v - vuoc).abs # distancia entre el brillo que dice el gris del color actual
          
          # modificamos el hue dependiendo de la dispersion de color que indique la template y el nivel de luminosidad
          # color_dispersion esta en grados
          cur_huoc = huoc
          if color_dispersion && v > 0.5
            cur_huoc = huoc + (((v-0.5)*2) * color_dispersion) /360.0 
            cur_huoc = cur_huoc - 1 if cur_huoc > 1.0
          elsif color_dispersion
            cur_huoc = huoc - ((v*2) * color_dispersion) /360.0
            cur_huoc = 1 - cur_huoc if cur_huoc < 0.0
          end
          #puts "huoc DISPERSION: orig #{huoc} | cur_huoc: #{cur_huoc}"
          
          
          if v < vuoc # el brillo solicitado es más claro, hacemos el color más claro de Lo q dice la plantilla
            newv = v + d*strength
          else
            newv = v - d*strength
          end
          #puts "#{huoc}, #{suoc}, #{newv}"
          newcolor = Skins::ColorGenerators::hsv_to_rgb(cur_huoc, suoc, newv) # (v + vuoc) / 2)
          im.colormap(i, "rgb(#{(newcolor[0]*255).to_i}, #{(newcolor[1]*255).to_i}, #{(newcolor[2]*255).to_i})")
          
          #puts "\nPROCESANDO COLOR DE PALETA #{i}"
          #puts "original RGB(#{color.red} #{color.green} #{color.blue}) HSV(#{h} #{s} #{v})"
          #puts "nuevo    RGB(#{(newcolor[0]*255).to_i}, #{(newcolor[1]*255).to_i}, #{(newcolor[2]*255).to_i}) HSV(#{huoc} #{s} #{(v + vuoc) / 2})"
        end
        im.write(newtmpfile)
        # FileUtils.cp("#{texture.dir}/file.png", newtmpfile)
        css = css_read_and_replace(texture, {:element_selector => user_options[:element_selector].gsub("'", '')})
        [css, [newtmpfile]]
        # TODO quién borra ese dir temporal?
      end
    end
    
    class STModuleHeaderAnomaly < AbstractTexture
      
    end
  end
end