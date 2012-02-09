require 'fileutils'
# mi propia versión de file_column
# guardas los archivos en storage/class_name_en_plural/hashed_subdir_basado_en_id/unique_filename
module SlncFileColumn
  # TODO incluir solo los métodos para instances a los objetos que tengan file_column!! (revisar init.rb)
  module ClassMethods
    def file_column(attrib, options={})
      class_eval <<-END
      @@file_column_attrs ||= []
      cattr_accessor :file_column_attrs unless self.respond_to?(:file_column_attrs)
      
      @@_fc_options ||= {}
      @@_fc_options[attrib] = options
      cattr_accessor :_fc_options unless self.respond_to?(:_fc_options)
      END
      
      define_method "#{attrib}=" do |file|
        self.file_column_attrs<< attrib
        @tmp_files ||= {}
        @old_files ||= {}
        @tmp_files[attrib.to_s] = file
        @old_files[attrib.to_s] = self[attrib.to_s]
        self[attrib.to_s] = file.to_s if (is_valid_upload(file)) # necesario para poder hacer validates_presence_of
        # raise "self[#{attrib.to_s}] = #{file.to_s} if (#{is_valid_upload(file)} && #{self[attrib.to_s].nil?})"
      end
      
      #define_method "#{attrib}" do 
      #  if object_instance_variable_get(attrib).nil? && defined?(@tmp_files) && @tmp_files.has_key?(attrib.to_s) 
      #    @tmp_files[attrib.to_s] 
      #  else 
      #    self[attrib]
      #  end
      #end
      
      define_method "#{attrib}" do
        self[attrib] # necesario por rails 2.2
      end
      
      # TODO after destroy
      
      after_save :save_uploaded_files
      after_destroy :destroy_file
      before_save :_fc_checks
    end
  end
  
  def _fc_file_name(tmp_file, orig=false)
    if tmp_file.respond_to?(:original_filename)
      orig ? tmp_file.original_filename : tmp_file.original_filename.bare
    elsif tmp_file.respond_to?(:path)
      orig ? File.basename(tmp_file.path) : File.basename(tmp_file.path).bare # para archivos subidos en masa
    else
      nil
    end
  end
  
  def _fc_checks
    if @tmp_files
      @tmp_files.keys.each do |f|
        next unless is_valid_upload(@tmp_files[f])
        
        hash_attrib = "#{f}_hash_md5".to_sym
        if self.respond_to?(hash_attrib) && !@tmp_files[f].nil?
          
          tmp_file = @tmp_files[f.to_s]
          if tmp_file.respond_to?('path') and tmp_file.path.to_s != '' then
            new_hash = file_hash(tmp_file.path)
          else # file size < 19Kb (es un StringIO)
            new_hash = Digest::MD5.hexdigest(tmp_file.read)
            tmp_file.rewind
          end
          if self.id
            if self.class.count(:conditions => ["id <> #{self.id} AND #{hash_attrib} = ?", new_hash]) > 0
              self.errors.add(f.to_sym, 'El archivo especificado ya existe')
              return false
            end
          else
            if self.class.count(:conditions => ["#{hash_attrib} = ?", new_hash]) > 0
              self.errors.add(f.to_sym, 'El archivo especificado ya existe')
              return false
            end
          end
          
        end
        
        # check format
        # check size (TODO)
        if self.class._fc_options[f.to_sym][:format]
          filename = _fc_file_name(@tmp_files[f])
          case self.class._fc_options[f.to_sym][:format]
            when :jpg then
            if !(/\.jpg$/i =~ filename)
              self.errors.add(f.to_sym, "El archivo #{_fc_file_name(tmp_file, true)} no es una imagen (Formato válido: JPG)")
              return false
            end           
          end
        end
      end
    end
    true
  end
  
  def save_uploaded_files
    if @tmp_files then
      # irb(main):024:0> my_id = 654321
      # => 654321
      # irb(main):025:0> (my_id/1000).to_s.rjust(4, '0')<<'/'<<(my_id%1000).to_s.rjust(3, '0')
      # => "0654/321"
      for f in @tmp_files.keys
        if is_valid_upload(@tmp_files[f]) then
          hash_attrib = "#{f}_hash_md5".to_sym
          File.unlink("#{RAILS_ROOT}/public/#{@old_files[f]}") if (@old_files[f].to_s != '' && File.exists?("#{RAILS_ROOT}/public/#{@old_files[f]}"))
          if @tmp_files[f].kind_of?(NilClass)
            self.class.db_query("UPDATE #{self.class.table_name} SET #{f} = NULL WHERE id = #{self.id}")
          else
            dir = self.class.table_name << '/' << (id/1000).to_s.rjust(4, '0')
            new_path = save_uploaded_file_to(@tmp_files[f], dir, (id%1000).to_s.rjust(3, '0'))
            self.class.db_query("UPDATE #{self.class.table_name} SET #{f} = '#{new_path.gsub(/'/, '\\\'')}' WHERE id = #{self.id}")
            if self.respond_to?(hash_attrib)
              hash = file_hash("#{RAILS_ROOT}/public/#{new_path}")
              self.class.db_query("UPDATE #{self.class.table_name} SET #{hash_attrib} = '#{hash}' WHERE id = #{self.id}")
            end
            @tmp_files.delete(f)
          end
        end
      end
      self.reload # necesario para que el modelo tenga los nuevos atributos
    end
  end

  def destroy_file
    for f in self.class.file_column_attrs
      File.unlink("#{RAILS_ROOT}/public/#{self[f]}") if (self[f].to_s != '' && File.exists?("#{RAILS_ROOT}/public/#{self[f]}"))
    end
  end

  #
  # Módulo para encapsular la forma de subir archivos a un directorio
  #
  def is_valid_upload(fileobj)
    # comprobamos path para archivos subidos en masa
    if fileobj.kind_of?(NilClass) or (fileobj.to_s != '' and \
       ((fileobj.respond_to?('original_filename') and fileobj.original_filename.bare.to_s != '') or (fileobj.respond_to?('path') && fileobj.path.to_s != ''))) then
      true
    end
  end

  def save_uploaded_file_to(tmp_file, path, prefix='')
    # guarda el archivo tmp_file en path. 
    #   tmp_file es un archivo tal y como viene de form
    #   path es el directorio donde se quiere guardar el archivo
    #   mode define qué hacer si ya existe un archivo con esa ruta
    #     find_unused, overwrite
    #
    #   ej de path recibido: users/1
            #   la función entiende que se refiere al dir: #{RAILS_ROOT}/public/storage/users/1/
            #
            #   ej de path devuelto: /storage/users/1/fulanito.jpg
            #
            # Si ya existe un archivo con ese nombre en path se busca uno único.
            # Devuelve la ruta absoluta final del archivo 
            
            # buscamos un nombre de archivo factible
            preppend = ''
            filename = _fc_file_name(tmp_file)
            
            if File.exists?("#{RAILS_ROOT}/public/storage/#{path}/#{prefix}_#{filename}") 
              incrementor = 1
              while File.exists?("#{RAILS_ROOT}/public/storage/#{path}/#{prefix}_#{incrementor}_#{filename}") 
                incrementor += 1
              end
              dst = "#{RAILS_ROOT}/public/storage/#{path}/#{prefix}_#{incrementor}_#{filename}"
            else
              dst = "#{RAILS_ROOT}/public/storage/#{path}/#{prefix}_#{filename}"
            end
            
            FileUtils.mkdir_p(File.dirname(dst)) if not File.directory?(File.dirname(dst))
            
            if tmp_file.respond_to?('path') and tmp_file.path.to_s != '' then
              FileUtils.cp(tmp_file.path, dst)
            else # file size < 19Kb (es un StringIO)
              File.open(dst, "wb") {|f| f.write(tmp_file.read) }
            end
            
            dst.gsub("#{RAILS_ROOT}/public/", '')
          end
          
          private
          # Calculates the md5 hash of filename somefile
          def file_hash(somefile)
            md5_hash = ''
            File.open(somefile) do |f| # binmode es vital por los saltos de línea y win/linux
              f.binmode
              md5_hash = Digest::MD5.hexdigest(f.read)
            end
            md5_hash
          end
        end
