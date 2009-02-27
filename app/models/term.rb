class Term < ActiveRecord::Base
  belongs_to :game
  belongs_to :bazar_district
  belongs_to :platform
  belongs_to :clan
  
  has_many :contents_terms #, :dependent => :destroy
  has_many :contents, :through => :contents_terms
  
  belongs_to :last_updated_item, :class_name => 'Content', :foreign_key => 'last_updated_item_id'
  # before_save :set_slug
  
  
  acts_as_rootable
  acts_as_tree :order => 'name'
  
  has_slug :name
  before_save :check_references_to_ancestors
  before_save :copy_parent_attrs
  
  # VALIDATES siempre los últimos
  validates_format_of :slug, :with => /^[a-z0-9_.-]{0,50}$/
  validates_format_of :name, :with => /^.{1,100}$/
  validates_uniqueness_of :name, :scope => [:game_id, :bazar_district_id, :platform_id, :clan_id, :taxonomy, :parent_id]
  validates_uniqueness_of :slug, :scope => [:game_id, :bazar_district_id, :platform_id, :clan_id, :taxonomy, :parent_id]
  
  def copy_parent_attrs
    return true if self.id == self.root_id
    
    par = self.parent
    self.game_id = par.game_id
    self.bazar_district_id = par.bazar_district_id
    self.platform_id = par.platform_id
    self.clan_id = par.clan_id
    self.taxonomy = par.taxonomy if par.taxonomy
    true
  end
  
  def code
    # TODO temp
    slug
  end
  
  def set_slug
    if self.slug.nil? || self.slug.to_s == ''
      self.slug = self.name.bare.downcase
      # TODO esto no comprueba si el slug está repetido
    end
    true
  end
  
  def mirror_category_tree(category, taxonomy)
    # DEPRECATED: Usado para migrar del sistema viejo de categorías al nuevo sistema de taxonomías
    raise "term is not root term" unless self.id == self.root_id && self.parent_id.nil?    
    
    # Cogemos todos los ancestros de la categoría dada y los vamos creando según sea conveniente
    the_parent = self
    taxonomy_name = category.class.name
    anc = category.get_ancestors
    anc.pop # quitamos toplevel
     ([category] + anc).reverse.each do |ancestor|
      newp = the_parent.children.find(:first, :conditions => ['taxonomy = ? AND name = ?', taxonomy_name, ancestor.name])
      if newp.nil?
        newp = the_parent.children.create(:root_id => the_parent.id, :name => ancestor.name, :taxonomy => taxonomy_name)
      end
      the_parent = newp
    end
    the_parent
  end
  
  def link(content)
    raise "TypeError, arg is #{content.class.name}" unless content.class.name == 'Content'
    if self.contents.find(:first, :conditions => ['contents.id = ?', content.id]).nil? # dupcheck
      if Cms::CATEGORIES_TERMS_CONTENTS.include?(content.content_type.name) && self.taxonomy.nil?
        puts "error: imposible enlazar categories_terms_content con un root_term"
        return false
      elsif Cms::ROOT_TERMS_CONTENTS.include?(content.content_type.name) && self.taxonomy && self.taxonomy.include('Category')
        puts "error: imposible enlazar root_terms_content con un category_term"
        return false
      end
      
      self.contents_terms.create(:content_id => content.id)
      
      # PERF esto hacerlo en accion secundaria?
      o = self
      while o
        Term.increment_counter(:contents_count, o.id)
        User.db_query("UPDATE terms SET comments_count = comments_count + #{content.comments_count}")
        o = o.parent
      end
      
      
      if self.id == self.root_id || self.taxonomy.include?('Category')
        content.url = nil
        ApplicationController.gmurl(content)
      end
    end
    true
  end
  
  def unlink(content)
    raise "TypeError" unless content.class.name == 'Content'
    self.contents_terms.find(:all, :conditions => ['content_id = ?', content.id]).each do |ct| 
      ct.destroy 
    end
    
    # PERF esto hacerlo en accion secundaria?
    o = self
    while o
      Term.decrement_counter(:contents_count, o.id)
      User.db_query("UPDATE terms SET comments_count = comments_count - #{content.comments_count}")
      o = o.parent
    end
    
    true
  end
  
  def self.find_taxonomy(id, taxonomy)
    sql_tax = taxonomy.nil? ? 'IS NULL' : "= #{User.connection.quote(taxonomy)}"
    Term.find(:first, :conditions => ["id = ? AND taxonomy #{sql_tax}", id])
  end
  
  def self.find_taxonomy_by_code(code, taxonomy)
    # Solo para taxonomías toplevel
    Term.find(:first, :conditions => ['id = root_id AND code = ? AND taxonomy = ?', code, taxonomy])
  end
  
  def self.toplevel(options={})
    conditions = 'id = root_id'
    if options[:clan_id]
      conditions << ' AND clan_id '
      conditions << (options[:clan_id].nil? ? 'IS NULL' : " = #{options[:clan_id].to_i}")
    end
    
    conditions << " AND slug = #{User.connection.quote(options[:slug])}" if options[:slug]
    conditions << " AND id = #{options[:id].to_i}" if options[:id]
    
    conditions << " AND game_id = #{options[:game_id].to_i}" if options[:game_id]
    conditions << " AND platform_id = #{options[:platform_id].to_i}" if options[:platform_id]
    conditions << " AND bazar_district_id = #{options[:bazar_district_id].to_i}" if options[:bazar_district_id]
    conditions << " AND clan_id = #{options[:clan_id].to_i}" if options[:clan_id]
    
    Term.find(:all, :conditions => conditions, :order => 'lower(name)')
  end
  
  def self.single_toplevel(opts={})
    self.toplevel(opts)[0]
  end
  
  # Devuelve los ids de los hijos de la categoría actual o de la categoría obj de forma recursiva incluido el id de obj
  def all_children_ids(opts={})
    cats = [self.id]
    conds = []
    conds << opts[:cond] if opts[:cond].to_s != ''
    conds << "taxonomy = #{User.connection.quote(opts[:taxonomy])}" if opts[:taxonomy]
    
    cond = ''
    cond = " AND #{conds.join(' AND ')}" if conds.size > 0
    
    
    if self.id == self.root_id then # shortcut
      db_query("SELECT id FROM terms WHERE root_id = #{self.id} AND id <> #{self.id} #{cond}").each { |dbc| cats<< dbc['id'].to_i }
    else # hay que ir preguntando categoría por categoría
      if conds.size > 0
        self.children.find(:all, :conditions => cond[4..-1]).each { |child| cats.concat(child.all_children_ids(opts)) }
      else
        self.children.find(:all).each { |child| cats.concat(child.all_children_ids(opts)) }
      end
    end
    cats.uniq
  end
  
  # devuelve portales relacionados con el término actual
  def get_related_portals
    portals = [GmPortal.new]
    if self.game_id || self.platform_id
      f = Faction.find_by_code(self.root.slug)
      if f
        portals += Portal.find(:all, :conditions => ['id in (SELECT portal_id from factions_portals where faction_id = ?)', f.id])  
      else
        puts "warning, term #{self.id} #{self.name} #{self.code} has no related_portals"
      end
    elsif self.bazar_district_id
      portals << BazarDistrictPortal.find_by_code(self.root.slug)
    elsif self.clan_id
      portals << ClansPortal.find_by_clan_id(self.root.clan_id)
    else # PERF devolvemos todos por contents como funthings 
      portals += Portal.find(:all, :conditions => 'type <> \'ClansPortal\'')
    end
    portals
  end
  
  def recalculate_counters
    # TODO 
  end
  
  def recalculate_contents_count
    #([self] + self.children.find(:all)).each do |t|
    #  newc = ContentsTerm.count(:conditions => "term_id IN (#{t.all_children_ids(t)})")
    #  t.contents_count = newc
    #  t.save
    #end
    newc = ContentsTerm.count(:conditions => "term_id IN (#{self.all_children_ids(self)})")
    self.contents_count = newc
    self.save
  end
  
  def recalculate_last_updated_item_id(excluding_id=nil)
    opts = {}
    opts[:conditions] = "id <> #{excluding_id}" if excluding_id
    self.last_updated_item_id = self.last_published_content(opts)
    self.save
  end
  
  def last_published_content(cls_name, opts={})
    # opts: user_id
    conds = []
    conds << "a.user_id = #{opts[:user_id].to_i}" if opts[:user_id]
    conds << opts[:conditions] if opts[:conditions] 
    cond = ''
    cond = " AND #{conds.join(' AND ')}" if conds.size > 0
    
    cat_ids = self.all_children_ids(:taxonomy => "#{Inflector::pluralize(cls_name)}Category")
    contents = Content.find_by_sql("SELECT a.* FROM contents a JOIN contents_terms b ON a.id = b.content_id WHERE b.term_id IN (#{cat_ids.join(',')}) AND a.state = #{Cms::PUBLISHED} #{cond} ORDER BY a.created_on DESC LIMIT 1")
    contents.size > 0 ? contents[0] : nil 
  end
  
  # valid opts keys: cls_name
  def contents_count(opts={})
    # TODO perf optimizar mas, si el tag tiene el mismo taxonomy que el solicitado
    raise "cls_name not specified" if self.taxonomy.nil? && opts[:cls_name].nil?
    if opts[:cls_name] != nil
      taxonomy = "#{Inflector::pluralize(opts[:cls_name])}Category"
      
      User.db_query("SELECT count(*) FROM contents WHERE id IN (SELECT content_id 
                                                              FROM contents_terms a 
                                                              JOIN terms b on a.term_id = b.id 
                                                             WHERE (a.term_id IN (#{all_children_ids(:taxonomy => taxonomy).join(',')}) 
                                                               AND b.taxonomy = #{User.connection.quote(taxonomy)})
                                                                OR a.term_id = #{self.id}
                                                            )")[0]['count'].to_i
      
    elsif self.taxonomy
      taxonomy = "#{Inflector::pluralize(self.taxonomy)}Category"
      self.count(:conditions => "contents_terms.term_id IN (SELECT term_id FROM contents_terms a JOIN terms b on a.term_id = b.id WHERE a.term_id IN (#{all_children_ids(:taxonomy => taxonomy)}) AND b.taxonomy = #{User.connection.quote(taxonomy)})")
    else # shortcut, show everything
      if self.attributes['contents_count'].nil?
        self.recalculate_contents_count 
      end
      self.attributes['contents_count']  
    end
  end
  
  
  def reset_contents_urls
    # TODO PERF más inteligencia
    self.find(:published, :treemode => true).each do |rc|
      uniq = rc.unique_content
      User.db_query("UPDATE contents SET url = NULL, portal_id = NULL WHERE id = #{uniq.id}")
      uniq.reload
      ApplicationController.gmurl(uniq)
      # self.children.each { |child| child.reset_contents}
    end
  end
  
  # Busca contenidos asociados a este término o a uno de sus hijos
  def find(*args)
    args = _add_cats_ids_cond(*args)
    self.contents.find(*args).collect { |cont| cont.real_content }
    # self.class.items_class.send(:find, *args)
  end
  
  def method_missing(method_id, *args)
    begin
      super
    rescue NoMethodError
      if Cms::CONTENTS_WITH_CATEGORIES.include?(Inflector::camelize(method_id.to_s))
        TermContentProxy.new(Inflector::camelize(method_id.to_s), self)
      elsif Inflector::camelize(Inflector::singularize(method_id.to_s))
        TermContentProxy.new(Inflector::camelize(Inflector::singularize(method_id.to_s)), self)
      else
        raise "No se que hacer con metodo #{method_id}"
        #args = _add_cats_ids_cond(*args)
        #begin
        #  self.class.items_class.send(method_id, *args)
        #rescue ArgumentError
        #  self.class.items_class.send(method_id)
        #end
      end
    end
  end
  
  def respond_to?(method_id, include_priv = false)
    self.class.items_class.respond_to?(method_id) || super
  end
  
  # Cuenta imágenes asociadas a esta categoría o a una de sus hijas
  # TODO se puede optimizar usando caches en categorías para images
  def count(*args)
    args = _add_cats_ids_cond(*args)
    opts = args.pop
    if opts.kind_of?(Hash)
      opts.delete(:joins)
      opts.delete(:order)
    end
    args.push(opts)
    self.contents.count(*args)
  end
  
  
  # acepta keys: treemode (true: incluye categorías de hijos)
  def _add_cats_ids_cond(*args)
    options = {:treemode => true}.merge(args.last.is_a?(Hash) ? args.pop : {}) # copypasted de extract_options_from_args!(args)
    @siblings ||= []
    if options[:treemode]
      @_cache_cats_ids ||= (self.all_children_ids + [self.id])
      @siblings.each { |s| @_cache_cats_ids += s.all_children_ids }
      # options[:conditions] = (options[:conditions]) ? ' AND ' : ''
      
      new_cond = "term_id IN (#{@_cache_cats_ids.join(',')})"
    else
      new_cond = "term_id IN (#{([self.id] + @siblings.collect { |s| s.id }).join(',')})"
    end
    
    if options[:content_type].nil? && options[:content_type_id].nil? && self.taxonomy.to_s.index('Category')
      options[:content_type] = ApplicationController.extract_content_name_from_taxonomy(self.taxonomy)
    end
    
    if options[:content_type]
      new_cond << " AND contents.content_type_id = #{ContentType.find_by_name(options[:content_type]).id}"
      options[:joins] = "JOIN #{Inflector::tableize(options[:content_type])} ON #{Inflector::tableize(options[:content_type])}.unique_content_id = contents.id"
    end
    
    
    if options[:content_type_id]
      new_cond << " AND contents.content_type_id = #{options[:content_type_id]}"
      ct = ContentType.find(options[:content_type_id])
      options[:joins] = "JOIN #{Inflector::tableize(ct.name)} ON #{Inflector::tableize(ct.name)}.unique_content_id = contents.id"
      #options[:include] ||= []
      #options[:include] << :contents
    end
    
    
    options.delete :treemode
    options.delete :content_type
    options.delete :content_type_id
    
    if options[:conditions].kind_of?(Array)
      options[:conditions][0]<< "AND #{new_cond}"
    elsif options[:conditions] then
      options[:conditions]<< " AND #{new_cond}"
    else
      options[:conditions] = new_cond
    end
    
    args.push(options)
    
    agfirst = args.first
    if agfirst.is_a?(Symbol) && [:drafts, :published, :deleted, :pending].include?(agfirst) then
      options = args.last.is_a?(Hash) ? args.pop : {} # copypasted de extract_options_from_args!(args)
      new_cond = "contents.state = #{Cms.const_get(agfirst.to_s.upcase)}"
      
      if options[:conditions].kind_of?(Array)
        options[:conditions][0]<< " AND #{new_cond} "
      elsif options[:conditions].to_s != '' then
        options[:conditions]<< " AND #{new_cond} "
      else
        options[:conditions] = new_cond
      end
      
      options[:order] = "contents.created_on DESC" unless options[:order]
      args[0] = :all
      
      args.push(options)
    end
    args
  end
  
  # devuelve el ultimo Content actualizado
  def get_last_updated_item
    if self.last_updated_item_id.nil? then
      cat_ids = self.all_children_ids
      obj = self.contents.find(:first, :order => 'updated_on DESC')
      
      if obj then
        # no usamos save para no tocar updated_on, created_on porque record_timestamps falla
        self.class.db_query("UPDATE terms SET last_updated_item_id = #{obj.id} WHERE id = #{self.id}")
        self.reload
        obj
      end
    else
      self.last_updated_item
    end
  end
  
  def random(limit=3)
    cat_ids = self.all_children_ids
    self.class.items_class.find(:all, :conditions => "state = #{Cms::PUBLISHED} and #{Inflector.underscore(self.class.name)}_id in (#{cat_ids.join(',')})", :order => 'RANDOM()', :limit => limit)
  end
  
  def most_rated_items(opts)
    raise "content_type unspecified" unless opts[:content_type]
    opts = {:limit => 5}.merge(opts)
    self.find(:published, 
              :content_type => opts[:content_type],
              :conditions => "cache_rated_times > 1", 
    :order => 'coalesce(cache_weighted_rank, 0) DESC', 
    :limit => opts[:limit])
  end
  
  def most_popular_items(opts)
    opts = {:limit => 3}.merge(opts)
    raise "content_type unspecified" unless opts[:content_type]
    self.find(:published, 
              :content_type => opts[:content_type],
              :conditions => "cache_rated_times > 1", 
    :order => '(coalesce(hits_anonymous, 0) + coalesce(hits_registered * 2, 0)+ coalesce(cache_comments_count * 10, 0) + coalesce(cache_rated_times * 20, 0)) DESC', 
    :limit => opts[:limit])
  end
  
  def comments_count
    # TODO perf
    User.db_query("SELECT SUM(A.comments_count) 
                     FROM contents A
                     JOIN contents_terms B ON A.id = B.content_id
                    WHERE B.term_id IN (#{all_children_ids})
                      AND A.state = #{Cms::PUBLISHED}")[0]['sum'].to_i
  end
  
  def last_created_items(limit = 3) # TODO esta ya sobra me parece, mirar en tutoriales
    self.find(:published,  
              :order => 'created_on DESC', 
    :limit => limit)
  end
  
  def random_item
    # TODO PERF usar campo random_id
    self.find(:published,  
              :order => 'random()')
  end
  
  def last_updated_items(limit = 5)
    self.find(:published,  
              :order => 'updated_on DESC', 
    :limit => limit)
  end
  
  
  def last_updated_children(opts={})
    opts = {:limit => 5}.merge(opts)
    Content.find_by_sql("SELECT * 
                           FROM contents 
                          WHERE id IN (SELECT last_updated_item_id 
                           FROM terms WHERE id IN (SELECT id FROM terms WHERE parent_id = #{self.id}))
                       ORDER BY updated_on DESC
                          LIMIT #{opts[:limit]}").collect { |c| c.terms[0] }.sort_by { |e| e.name.downcase }
  end
  
  
  # TODO tests
  def most_active_users(taxonomy)
    # los usuarios más activos son los que más karma han contribuido al foro en
    # el último mes
    # el máximo de usuarios a mostrar es 3 por lo tanto el algoritmo lo que hace es buscar el top 10 de usuarios que han contribuído tópics más el top 10 de usuarios que han contribuído comentarios
    # sumamos el karma generado por ambos tops y cogemos el top 3. El único problema que podría haber es que un 
    # usuario que haya contribuído menos que el top 10 de ambas cosas en total sumen más que el top 3 de 
    # comentarios y el top 3 de usuarios pero estimo que con el margen de top 10 para un top 3 las 
    # probabilidades de que esto ocurra son mínimas
    time_interval = '1 month'
    tbl = {}
    raise "unsupported" unless taxonomy == 'TopicsCategory'
    sql_taxo = taxonomy ? "= #{User.connection.quote(ApplicationController.extract_content_name_from_taxonomy(taxonomy))}" : 'IS NULL'
    # cogemos el top 3 de topics
    # aunque el tópic tenga más de 3 meses el poster sigue contando si sigue activo
    for t in User.db_query("SELECT count(A.id), 
                                      A.user_id 
                                 FROM contents A
                                 JOIN contents_terms B on A.id = B.content_id  
                                WHERE A.updated_on > (now() -  '#{time_interval}'::interval)
                                  AND state = #{Cms::PUBLISHED} 
                                  AND B.term_id IN (#{all_children_ids(:taxonomy => taxonomy).join(',')})
                             GROUP BY user_id, content_type_id
                             ORDER BY count(A.id) DESC LIMIT 10")
      
      tbl[t['user_id'].to_i] = {:karma_sum => Karma::KPS_CREATE['Topic'] * t['count'].to_i, 
        :topics => t['count'].to_i,
        :count => t['count'].to_i,
        :comments => 0} 
    end
    
    # buscamos todos los topics actualizados en el ultimo intervalo y cogemos el top 3 de 
    # users que hayan comentado
    # cogemos el top 3 de comentarios
    
    Content.find_by_sql("SELECT contents.*
                             FROM contents 
                             JOIN contents_terms on contents.id = contents_terms.content_id
                            WHERE term_id IN (#{all_children_ids})
                              AND state = #{Cms::PUBLISHED}
                              AND updated_on > (now() -  '#{time_interval}'::interval)").each do |content|
      t = content.real_content
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
  
  def most_active_items(content_type)
    # TODO per hit
    # TODO no filtramos
    self.find(:published, 
              :conditions => "contents.updated_on > now() - '3 months'::interval",
    :content_type => content_type,
    :order => '(contents.comments_count / extract (epoch from (now() - contents.created_on))) desc',
    :limit => 5)
  end
  
  
  def top_contributors(opts)
    total = User.db_query("SELECT count(DISTINCT(A.id)) 
                                 FROM contents A
                                 JOIN contents_terms B ON A.id = B.content_id
                                  AND B.term_id IN (#{all_children_ids(opts.pass_sym(:taxonomy)).join(',')}) 
                                WHERE state = #{Cms::PUBLISHED}")[0]['count'].to_f
    
    # TODO tests
    # devuelve el usuario que más contenidos ha aportado a la categoría
    User.db_query("SELECT user_id, count(DISTINCT(A.id)) 
                                 FROM contents A
                                 JOIN contents_terms B ON A.id = B.content_id
                                  AND B.term_id IN (#{all_children_ids(opts.pass_sym(:taxonomy)).join(',')}) 
                                WHERE state = #{Cms::PUBLISHED} 
                             GROUP BY user_id 
                             ORDER BY count(A.id) DESC 
                                LIMIT #{opts[:limit]}").collect do |dbr|
      {:user => User.find(dbr['user_id'].to_i), :count => dbr['count'].to_i, :pcent => dbr['count'].to_i / total}  
    end
  end
  
  # TODO DEPRECATED, desactivar y corregir tests que fallen
  def active_items(limit=15)
    last_updated_items(limit)
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
  
  def self.find_by_toplevel_group_code(code)
    case code
      when 'gm':
      Term.single_toplevel(:slug => 'gm').children.find(:all, :order => 'lower(name)')
      when 'juegos':
      Term.find(:all, :conditions => 'id = root_id AND game_id IS NOT NULL', :order => 'lower(name)')
      when 'plataformas':
      Term.find(:all, :conditions => 'id = root_id AND platform_id IS NOT NULL', :order => 'lower(name)')
      when 'arena':
      Term.single_toplevel(:slug => 'arena').children.find(:all, :order => 'lower(name)')
      when 'bazar':
      Term.find(:all, :conditions => 'id = root_id AND bazar_district_id IS NOT NULL', :order => 'lower(name)')
    else
      raise "toplevel group code '#{code}' unknown"
    end
  end
  
  private
  def check_references_to_ancestors
    if !self.new_record?
      if slnc_changed?(:parent_id) then
        return false if self.parent_id == self.id # para evitar bucles infinitos
        self.root_id = parent_id.nil? ? self.id : self.class.find(parent_id).root_id
        self.class.find(:all, :conditions => "id IN (#{self.all_children_ids.join(',')})").each do |child|
          next if child.id == self.id
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
end

class TermContentProxy
  def initialize(content_name, term)
    @cls_name = content_name
    @term = term
  end
  
  def method_missing(method_id, *args)
    begin
      super
    rescue NoMethodError
      opts = args.last.is_a?(Hash) ? args.pop : {}
      opts[:content_type] = @cls_name
      args.push(opts)
      args = @term._add_cats_ids_cond(*args)
      
      opts = args.last.is_a?(Hash) ? args.pop : {}
      if method_id == :count # && opts[:joins]
        opts.delete :joins
        opts.delete :order
      end
      args.push(opts)
      
      begin
        res = @term.contents.send(method_id, *args)
        res.kind_of?(Array) ? res.collect { |cont| cont.real_content } : res
      rescue ArgumentError
        @term.contents.send(method_id)
      end
    end
  end
end