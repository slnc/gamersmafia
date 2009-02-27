module CategoryActing
  # INSTALL
  #  1. add "require 'category_acting'" to bottom of environment.rb
  #  2. add "act_as_category" to class definition
  #
  #  NOTE: models whichs this categorises must be named like NewsCategories, DownloadsCategories, etc
  def self.included(base)
    base.extend AddActAsMethod
  end
  
  module AddActAsMethod
    def act_as_category
      acts_as_rootable
      
      after_create :check_parent_id_on_create # TODO maybe this one should go away now
      
      acts_as_tree :order => 'name'
      
      
      has_many Inflector.pluralize(self.name.gsub(/Category/, '').downcase).to_sym
      belongs_to :root, :class_name => self.name, :foreign_key => 'root_id'
      has_one :last_updated_item, :class_name => self.name.gsub(/Category/, '')
      has_one :competition if name == 'TopicsCategory' # TODO hack
      file_column :file
      before_save :check_references_to_ancestors
      validates_uniqueness_of :name, :scope => :parent_id
      
      class_eval <<-END
        include CategoryActing::InstanceMethods
        extend CategoryActing::ExtendMethods
      END
    end
    
    def items_class
      Object.const_get(Inflector.singularize(self.name.gsub('Category', '')))
    end
  end
  
  module InstanceMethods
    def check_references_to_ancestors
      if !self.new_record?
        if slnc_changed?(:parent_id) then
          return false if self.parent_id == self.id # para evitar bucles infinitos
          self.root_id = parent_id.nil? ? self.id : self.class.find(parent_id).root_id
          self.class.find(:all, :conditions => "id IN (#{self.all_children_ids.join(',')})").each do |child|
            child.root_id = self.root_id
            child.save
          end
        end
        
        # TODO Rails 2.1 (dirty tracking)
        if slnc_changed?(:root_id) && self.root_id != self.slnc_changed_old_values[:root_id] then # reseteamos la url de todos los contenidos aquí y en categorías inferiores
          GmSys.job("#{self.class.name}.find(#{self.id}).reset_contents_urls")
        end
      end
      true
    end
    
    def reset_contents_urls
      # TODO PERF más inteligencia
      self.find(:all).each do |rc|
        uniq = rc.unique_content
        User.db_query("UPDATE contents SET url = NULL, portal_id = NULL WHERE id = #{uniq.id}")
        uniq.reload
        ApplicationController.gmurl(uniq)
        # self.children.each { |child| child.reset_contents}
      end
    end
    
    # acepta keys: treemode (true: incluye categorías de hijos)
    #              content_type_id: restringir a contenidos del tipo dado
    def _add_cats_ids_cond(*args)
      options = {:treemode => true}.merge(args.last.is_a?(Hash) ? args.pop : {}) # copypasted de extract_options_from_args!(args)
      @siblings ||= []
      if options[:treemode]
        @_cache_cats_ids ||= (all_children_ids + [self.id])
        @siblings.each { |s| @_cache_cats_ids += s.all_children_ids }
        # options[:conditions] = (options[:conditions]) ? ' AND ' : ''
        
        new_cond = "#{Inflector::underscore(self.class.name)}_id IN (#{@_cache_cats_ids.join(',')})"
      else
        new_cond = "#{Inflector::underscore(self.class.name)}_id IN (#{([self.id] + @siblings.collect { |s| s.id }).join(',')})"
      end
      options.delete :treemode
      
      if options[:conditions].kind_of?(Array)
        options[:conditions][0]<< "AND #{new_cond}"
      elsif options[:conditions] then
        options[:conditions]<< " AND #{new_cond}"
      else
        options[:conditions] = new_cond
      end
      args.push(options)
    end
    
    def method_missing(method_id, *args)
      begin
        super
      rescue NoMethodError
        if method_id == :find_by_sql
          self.class.items_class.send(method_id, *args)
        else
          args = _add_cats_ids_cond(*args)
          begin
            self.class.items_class.send(method_id, *args)
          rescue ArgumentError
            self.class.items_class.send(method_id)
          end
        end
      end
    end
    
    def respond_to?(method_id, include_priv = false)
      self.class.items_class.respond_to?(method_id) || super
    end
    
    # añade la categoría dada a la lista de categorías hermanas de esta. Se usa
    # para métodos find y count para poder usar el objeto categoría como
    # buscador de contenidos
    def add_sibling(cat)
      @siblings ||= []
      @siblings<< cat
    end
    
    def open_bets
      args = _add_cats_ids_cond({})
      self.class.items_class.send(:open_bets, *args)
    end
    
    def awaiting_result(*args)
      args = _add_cats_ids_cond(*args)
      self.class.items_class.send(:awaiting_result, *args)
    end
    
    def closed_bets(*args)
      args = _add_cats_ids_cond(*args)
      self.class.items_class.send(:closed_bets, *args)
    end
    
    # Busca imágenes asociadas a esta categoría o a una de sus hijas
    def find(*args)
      args = _add_cats_ids_cond(*args)
      self.class.items_class.send(:find, *args)
    end
    
    # Cuenta imágenes asociadas a esta categoría o a una de sus hijas
    # TODO se puede optimizar usando caches en categorías para images
    def count(*args)
      args = _add_cats_ids_cond(*args)
      self.class.items_class.send(:count, *args)
    end
    
    def get_ancestors 
      # devuelve los ascendientes. en [0] el padre directo y en el último el root
      path = []
      parent = self.parent
      
      while parent do
        path<< parent
        parent = parent.parent
      end
      
      path
    end
    
    def calculate_popularity
      self.db_query("UPDATE topics_categories SET avg_popularity = COALESCE((select avg(cache_comments_count / extract(EPOCH FROM now() - created_on)) from topics where topics_category_id = #{self.id} and created_on > now() - '1 month'::interval), 0) WHERE id = #{self.id}")
    end
    
    # TODO copypasted
    def most_active_users
      # los usuarios más activos son los que más karma han contribuido al foro en
      # el último mes
      # el máximo de usuarios a mostrar es 3 por lo tanto el algoritmo lo que hace es buscar el top 10 de usuarios que han contribuído tópics más el top 10 de usuarios que han contribuído comentarios
      # sumamos el karma generado por ambos tops y cogemos el top 3. El único problema que podría haber es que un 
      # usuario que haya contribuído menos que el top 10 de ambas cosas en total sumen más que el top 3 de 
      # comentarios y el top 3 de usuarios pero estimo que con el margen de top 10 para un top 3 las 
      # probabilidades de que esto ocurra son mínimas
      time_interval = '1 month'
      tbl = {}
      
      cat_ids = [self.id]
      for c in self.children
        cat_ids<< c.id
        if c.children.size > 0 then
          for cc in c.children
            cat_ids<< cc.id
            if cc.children.size > 0 then
              for ccc in cc.children
                cat_ids<< ccc.id
              end
            end
          end
        end
      end
      
      # cogemos el top 3 de topics
      # aunque el tópic tenga más de 3 meses el poster sigue contando si sigue activo
      for t in Topic.db_query("SELECT count(id), 
                                      user_id 
                                 FROM topics 
                                WHERE updated_on > (now() -  '#{time_interval}'::interval)
                                  AND state = #{Cms::PUBLISHED} 
                                  AND topics_category_id IN (#{cat_ids.join(',')}) 
                             GROUP BY user_id 
                             ORDER BY count(id) DESC LIMIT 10")
        
        tbl[t['user_id'].to_i] = {:karma_sum => Karma::KPS_CREATE['Topic'] * t['count'].to_i, 
          :topics => t['count'].to_i,
          :comments => 0} 
      end
      
      # buscamos todos los topics actualizados en el ultimo intervalo y cogemos el top 3 de 
      # users que hayan comentado
      # cogemos el top 3 de comentarios
      for t in Topic.find(:all, :conditions => "state = #{Cms::PUBLISHED} 
                                            AND topics_category_id IN (#{cat_ids.join(',')}) 
                                            AND updated_on > (now() -  '#{time_interval}'::interval)")
        for c in Comment.db_query("SELECT count(id), 
                                          user_id 
                                     from comments 
                                    where deleted = 'f' 
                                      AND content_id = #{t.unique_content.id} 
                                      AND created_on >= (now() -  '#{time_interval}'::interval)
                                 group by user_id 
                                 order by count(id) DESC")
          
          tbl[c['user_id'].to_i] = {:karma_sum => 0, :topics => 0, :comments => 0} unless tbl[c['user_id'].to_i]
          tbl[c['user_id'].to_i][:karma_sum] += Karma::KPS_CREATE['Comment'] * c['count'].to_i
          tbl[c['user_id'].to_i][:comments] += c['count'].to_i
        end
      end
      
      # cogemos el top 3
      # sumamos los puntos de todos y elegimos
      first = nil
      second = nil
      third = nil
      
      tbl.keys.each do |u|
        if first.nil? or tbl[u][:karma_sum] > tbl[first[0]][:karma_sum] then
          first = u, tbl[u]
        elsif second.nil? or tbl[u][:karma_sum] > tbl[second[0]][:karma_sum] then
          second = u, tbl[u]
        elsif third.nil? or tbl[u][:karma_sum] > tbl[third[0]][:karma_sum] then
          third = u, tbl[u]
        end
      end
      
      # NOTA: tb contamos comentarios de hace más de 3 meses en el top 3 de comentarios
      # buscamos el total de karma generado por este topic
      # dbtotal = Topic.db_query("SELECT count(id) as topics, COALESCE(sum(cache_comments_count), 0) as comments from topics where updated_on > (now() -  '3 months'::interval) and topics_category_id IN (#{cat_ids.join(',')})")[0]
      max = first ? first[1][:karma_sum] : 1 # no es 0 para no dividir por 0
      
      result = []
      if first
        first[1][:relative_pcent] = 1.0
        result<< [User.find(first[0]), first[1]]
      end
      
      if second
        second[1][:relative_pcent] = second[1][:karma_sum].to_f / max
        result<< [User.find(second[0]), second[1]]
      end
      
      if third
        third[1][:relative_pcent] = third[1][:karma_sum].to_f / max
        result<< [User.find(third[0]), third[1]]  
      end
      
      result
    end
    
    
    def active_items(limit=15)
      cat_ids = [self.id]
      for c in self.children
        cat_ids<< c.id
        if c.children.size > 0 then
          for cc in c.children
            cat_ids<< cc.id
            if cc.children.size > 0 then
              for ccc in cc.children
                cat_ids<< ccc.id
              end
            end
          end
        end
      end
      
      self.class.items_class.find(:published, :conditions => "#{Inflector::underscore(self.class.name)}_id IN (#{cat_ids.join(',')})", :order => 'updated_on DESC', :limit => limit)
    end
    
    def most_active_items
      cat_ids = [self.id]
      for c in self.children
        cat_ids<< c.id
        if c.children.size > 0 then
          for cc in c.children
            cat_ids<< cc.id
            if cc.children.size > 0 then
              for ccc in cc.children
                cat_ids<< ccc.id
              end
            end
          end
        end
      end
      
      # TODO per hit
      # TODO no filtramos
      if self.class.name == 'TopicsCategory' then # eliminamos las categorías ocultas
        TopicsCategory.find(:all, :conditions => 'nohome = \'t\'').each do |cat|
          cat_ids.delete(cat.id) unless cat.id == self.id
        end
      end
      
      self.class.items_class.find_by_sql("SELECT a.*
                                    FROM #{Inflector::tableize(self.class.items_class.name)} a join contents b on a.id = b.external_id and b.content_type_id = 6 
                                   WHERE #{Inflector::underscore(self.class.name)}_id IN (#{cat_ids.join(',')}) and a.updated_on > now() - '3 months'::interval
                                     AND a.state = #{Cms::PUBLISHED}
                                ORDER BY (comments_count / extract (epoch from (now() - a.created_on))) desc 
                                   LIMIT 5")
    end
    
    
    
    def last_topics
      # TODO mover el chequeo de condición
      #return Topic.find(:all, :conditions => "deleted is false and topics_category_id IN (select id from topics_categories where parent_id = #{id}) and updated_on > now() - \'2 days\'::interval", :order => 'updated_on desc', :limit => 3)
      return Topic.find(:all, :conditions => "state = #{Cms::PUBLISHED} and topics_category_id IN (select id from topics_categories where parent_id = #{id})", :order => 'updated_on desc', :limit => 3)
      #return self.topics.find(:all, :limit => 5)
    end
    
    
    
    def items_count(obj = nil, force = false)
      obj = self if obj.nil?
      attr_count = "#{Inflector::pluralize(Inflector::underscore(obj.class.items_class.name)).downcase}_count"
      
      if obj.attributes[attr_count].nil? or force then
        # obj es una instancia de una categoría
        count = obj.class.items_class.count(:conditions => "#{(Inflector::underscore(self.class.name)).downcase}_id = #{obj.id} and state = #{Cms::PUBLISHED}")
        
        for i in obj.children
          raise "#{i.id} error al contar items_count en categoría" if items_count(i).nil?
          count += items_count(i)
        end
        
        # no usamos save para no tocar updated_on, created_on porque record_timestamps falla
        obj.class.db_query("UPDATE #{Inflector::tableize(self.class.name)} SET #{attr_count} = #{count} WHERE id = #{self.id}")
        obj.reload
      end
      
      obj.attributes[attr_count]
    end
    
    
    def top_contributor
      # devuelve el usuario que más contenidos ha aportado a la categoría
      us_info = User.db_query("select user_id, count(id) from #{Inflector.tableize(self.class.items_class.name)} where #{Inflector.underscore(self.class.name)}_id = #{self.id} and state = #{Cms::PUBLISHED} group by user_id order by count(id) desc limit 1")[0]
      
      if not us_info then
        return 
      end
      
      top_contributor = User.find(us_info['user_id'])
      return top_contributor, us_info['count']
    end
    
    
    def last_updated(limit = 5)
      # TODO meter aquí la constraint de size para no devolver categorías sin subcategorías y quitarlo de la view
      return self.children.find(:all, :order => 'updated_on desc', :limit => limit)
    end
    
    def get_last_updated_item
      if self.last_updated_item_id.nil? then
        cat_ids = self.all_children_ids
        
        if self.class.items_class.name == 'Topic' then
          obj = self.class.items_class.find(:first, :conditions => "state = #{Cms::PUBLISHED} and sticky is false and closed is false and #{Inflector.underscore(self.class.name)}_id in (#{cat_ids.join(',')})", :order => 'updated_on DESC')
        else
          obj = self.class.items_class.find(:first, :conditions => "state = #{Cms::PUBLISHED} and #{Inflector.underscore(self.class.name)}_id in (#{cat_ids.join(',')})", :order => 'updated_on DESC')
        end
        
        if obj then
          # no usamos save para no tocar updated_on, created_on porque record_timestamps falla
          self.class.db_query("UPDATE #{Inflector::tableize(self.class.name)} SET last_updated_item_id = #{obj.id} WHERE id = #{self.id}")
          self.reload
          obj
        end
      else
        self.last_updated_item_id
      end
    end
    
    def get_related_portals
      portals = [GmPortal.new]
      return portals # shortcut due to new taxonomies system
      
      f = Organizations.find_by_content(self.class.items_class.new("#{Inflector::singularize(Inflector::tableize(self.class.name))}_id".to_sym => self.id))
      if f.nil? then # No es un contenido de facción o es de categoría gm/otros TODO PERF esto no usarlo con caches, madre del amor hermoso
        portals += Portal.find(:all, :conditions => 'type <> \'ClansPortal\'')
      elsif f.class.name == 'Faction'
        # TODO plataforma PC va a fallar
        portals += Portal.find(:all, :conditions => ['id in (SELECT portal_id from factions_portals where faction_id = ?)', f.id])
      else
        portals<< BazarPortal.new
      end
      portals
    end
    
    def last_updated_items(limit = 5)
      cat_ids = self.all_children_ids
      self.class.items_class.find(:all, :conditions => "state = #{Cms::PUBLISHED} and #{Inflector.underscore(self.class.name)}_id in (#{cat_ids.join(',')})", :order => 'updated_on DESC', :limit => limit)
    end
    
    # Devuelve los ids de los hijos de la categoría actual o de la categoría obj de forma recursiva incluido el id de obj
    def all_children_ids(obj = nil)
      obj = self if obj.nil?
      cats = [obj.id]
      
      if obj.id == obj.root_id then # shortcut
        # puts "select id from #{Inflector.tableize(self.class.name)} where root_id = #{obj.id} and id <> #{obj.id}"
        db_query("select id from #{Inflector.tableize(self.class.name)} where root_id = #{obj.id} and id <> #{obj.id}").each { |dbc| cats<< dbc['id'].to_i }
      else # hay que ir preguntando categoría por categoría
        #        db_cats = db_query("select id from #{Inflector.tableize(self.class.name)} where parent_id = #{self.id}")
        obj.children.each { |i| cats.concat(all_children_ids(i)) }
      end
      cats.uniq
    end
    
    def random(limit=3)
      cat_ids = self.all_children_ids
      self.class.items_class.find(:all, :conditions => "state = #{Cms::PUBLISHED} and #{Inflector.underscore(self.class.name)}_id in (#{cat_ids.join(',')})", :order => 'RANDOM()', :limit => limit)
    end
    
    def most_rated_items(limit=3)
      cat_ids = self.all_children_ids
      self.class.items_class.find(:all, :conditions => "state = #{Cms::PUBLISHED} and cache_rated_times > 1 and #{Inflector.underscore(self.class.name)}_id in (#{cat_ids.join(',')})", :order => 'coalesce(cache_weighted_rank, 0) DESC', :limit => limit)
    end
    
    def most_popular_items(limit=3)
      cat_ids = self.all_children_ids
      self.class.items_class.find(:all, :conditions => "state = #{Cms::PUBLISHED} and cache_rated_times > 1 and #{Inflector.underscore(self.class.name)}_id in (#{cat_ids.join(',')})", :order => '(coalesce(hits_anonymous, 0) + coalesce(hits_registered * 2, 0)+ coalesce(cache_comments_count * 10, 0) + coalesce(cache_rated_times * 20, 0)) DESC', :limit => limit)
    end
    
    def last_created_items(limit = 3) # TODO esta ya sobra me parece, mirar en tutoriales
      cat_ids = self.all_children_ids
      self.class.items_class.find(:all, :conditions => "state = #{Cms::PUBLISHED} and #{Inflector.underscore(self.class.name)}_id in (#{cat_ids.join(',')})", :order => 'created_on DESC', :limit => limit)
    end
    
    def random_item
      cat_ids = self.all_children_ids
      self.class.items_class.find(:first, :conditions => "state = #{Cms::PUBLISHED} and #{Inflector.underscore(self.class.name)}_id in (#{cat_ids.join(',')})", :order => 'random()')
    end
  end
  
  module ExtendMethods
    def most_popular_items
      self.items_class.find(:all, :conditions => "state = #{Cms::PUBLISHED}", :order => '(coalesce(hits_anonymous, 0) + coalesce(hits_registered * 2, 0)+ coalesce(cache_comments_count * 10, 0) + coalesce(cache_rated_times * 20, 0)) DESC', :limit => 3)
      
      # select avg(coalesce(hits_anonymous, 0) + coalesce(hits_registered * 2, 0)+ coalesce(cache_comments_count * 10, 0) + coalesce(cache_rated_times * 20, 0)) as foo from news where updated_on > now() - '3 months'::interval;
    end
    
    def most_rated_items(limit=3)
      self.items_class.find(:all, :conditions => "state = #{Cms::PUBLISHED} and cache_rated_times > 1", :order => 'coalesce(cache_rating, 0) DESC', :limit => limit)
    end
    
    def toplevel(opts={})
      opts = {:limit => :all, :order => 'lower(name) ASC'}.merge(opts)
      qcond = ' parent_id is null and root_id = id'
      qcond << " AND #{opts[:conditions]}" if opts[:conditions]
      qcond << " AND clan_id is null" if Cms::CLANS_CONTENTS.include?(self.items_class.name)
      find(:all, :conditions => qcond, :limit => opts[:limit], :order => opts[:order])
    end
    
    def toplevel_groups
      [['Gamersmafia', 'gm'], 
      ['Juegos', 'juegos'],
      ['Plataformas', 'plataformas'],
      ['Arena', 'arena'],
      ['Bazar', 'bazar'],
      ]
    end
    
    def find_by_toplevel_group_code(code)
      case code
        when 'gm':
        find_by_code('gm').children.find(:all, :order => 'lower(name)')
        when 'juegos':
        sql_platforms = Game.find(:all).collect { |g| "'#{g.code}'" }
        find(:all, :conditions => "root_id = id AND code IN (#{sql_platforms.join(',')})", :order => 'lower(name)')
        when 'plataformas':
        sql_platforms = Platform.find(:all).collect { |plt| "'#{plt.code}'" }
        find(:all, :conditions => "root_id = id AND code IN (#{sql_platforms.join(',')})", :order => 'lower(name)')
        when 'arena':
        find_by_code('arena').children.find(:all, :order => 'lower(name)')
      when 'bazar':
        sql_districts = BazarDistrict.find(:all).collect { |g| "'#{g.code}'" }
        find(:all, :conditions => "root_id = id AND code IN (#{sql_districts.join(',')})", :order => 'lower(name)')
      else
         raise "toplevel group code '#{code}' unknown"
      end
    end
  end
end

ActiveRecord::Base.send(:include, CategoryActing)