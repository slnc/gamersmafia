require 'has_slug'

class Term < ActiveRecord::Base
  belongs_to :game
  belongs_to :bazar_district
  belongs_to :platform
  belongs_to :clan

  scope :contents_tags, :conditions => 'taxonomy = \'ContentsTag\''
  scope :not_contents_tags, :conditions => 'taxonomy IS NULL or taxonomy <> \'ContentsTag\''
  scope :top_level, :conditions => 'id = root_id AND parent_id IS NULL AND clan_id IS NULL'
  scope :with_taxonomy, lambda { |taxonomy| {:conditions => "taxonomy = '#{taxonomy}'"}}
  scope :in_category, lambda { |t| { :conditions => ['id IN (SELECT term_id FROM contents_terms WHERE content_id IN (SELECT content_id FROM contents_terms WHERE term_id IN (?)))', t.all_children_ids]} }

  has_many :contents_terms, :dependent => :destroy
  has_many :contents, :through => :contents_terms
  has_many :users_contents_tags #, :dependent => :destroy
  has_many :tagged_contents, :through => :users_contents_tags, :source => :content

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
  plain_text :name, :description
  validates_uniqueness_of :name, :scope => [:game_id, :bazar_district_id, :platform_id, :clan_id, :taxonomy, :parent_id]
  validates_uniqueness_of :slug, :scope => [:game_id, :bazar_district_id, :platform_id, :clan_id, :taxonomy, :parent_id]
  before_save :check_scope_if_toplevel

  def orphan?
    self.contents.count == 0
  end

  def contents_tagged_count
    raise "Invalid taxonomy" unless self.taxonomy == 'ContentsTag'
    User.db_query("SELECT count(distinct(content_id)) FROM users_contents_tags WHERE term_id = #{self.id}")[0]['count'].to_i
  end

  def check_scope_if_toplevel
    if self.new_record? && self.parent_id.nil?
       if Term.count(:conditions => ['parent_id IS NULL AND slug = ?', self.slug]) > 0
	       self.errors.add('slug', 'Slug is already taken')
	       false
       else
	       true
       end
    elsif (!self.new_record?) && self.parent_id.nil?
       if Term.count(:conditions => ['id <> ? AND parent_id IS NULL AND slug = ?', self.id, self.slug]) > 0
	       self.errors.add('slug', 'Slug is already taken')
	       false
       else
	       true
       end
    else
       true
    end
  end

  before_destroy :sanity_check

  def sanity_check
    true # return false if self.contents_count > 25
  end

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

  def add_content_type_mask(content_type)
    @content_type_mask = content_type
  end

  def set_slug
    if self.slug.nil? || self.slug.to_s == ''
      self.slug = self.name.bare.downcase
      # TODO esto no comprueba si el slug está repetido
    end
    true
  end

  def import_mode
    @_import_mode || false
  end

  def set_import_mode
    @_import_mode = true
  end

  def link(content, normal_op=true)
    raise "TypeError, arg is #{content.class.name}" unless content.class.name == 'Content'
    return true unless self.contents.find(:first, :conditions => ['contents.id = ?', content.id]).nil? # dupcheck

    if Cms::CATEGORIES_TERMS_CONTENTS.include?(content.content_type.name) && self.taxonomy.nil?
      # Rails.logging.error "imposible enlazar categories_terms_content con un root_term, enlazando con un hijo"
      return false if normal_op
      taxo = "#{ActiveSupport::Inflector::pluralize(content.content_type.name)}Category"
      t = self.children.find(:first, :conditions => "taxonomy = '#{taxo}'")
      t = self.children.create(:name => 'General', :taxonomy => taxo) if t.nil?
      t.link(content, normal_op)
      #return false
    elsif Cms::ROOT_TERMS_CONTENTS.include?(content.content_type.name) && self.taxonomy && self.taxonomy.index('Category')
      Rails.logging.warning "error: imposible enlazar root_terms_content con un category_term, enlazando con root"
      return false if normal_op
      self.root.link(content, normal_op)
      #return false
    end

    ct = self.contents_terms.create(:content_id => content.id)

    if normal_op # TODO quitar esto despues de 2009.1
      self.recalculate_last_updated_item_id
      # PERF esto hacerlo en accion secundaria?

      o = self
      while o
        Term.increment_counter(:contents_count, o.id)
        User.db_query("UPDATE terms SET comments_count = comments_count + #{content.comments_count} WHERE id = #{o.id}")
        o = o.parent
      end

      if self.id == self.root_id || self.taxonomy.include?('Category')
        content.url = nil
        Routing.gmurl(content)
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
    self.recalculate_last_updated_item_id

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
    Term.find(:all, :conditions => conditions, :order => 'lower(name)')
  end

  def self.single_toplevel(opts={})
    raise "Invalid single_toplevel, opts must be Hash!" if opts.class.name != 'Hash'
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
      #else
        #puts "warning, term #{self.id} #{self.name} #{self.code} has no related_portals"
      end
    elsif self.bazar_district_id
      portals << self.bazar_district
    elsif self.clan_id
      portals << ClansPortal.find_by_clan_id(self.clan_id)
    else # PERF devolvemos todos por contents como funthings
      portals += Portal.find(:all, :conditions => 'type <> \'ClansPortal\'')
    end
    portals
  end

  def recalculate_counters
    recalculate_contents_count
    last = self.get_last_updated_item
    if last && last.state == Cms::DELETED
      self.last_updated_item_id = nil
      # self.save
      self.get_last_updated_item
    end
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
    opts[:conditions] = "a.id <> #{excluding_id}" if excluding_id
    last = self.last_published_content(nil, opts)
    if last
      self.last_updated_item_id = last.id
      self.save
    end
    self.parent.recalculate_last_updated_item_id(excluding_id) if self.parent
    true
  end

  def last_published_content(cls_name, opts={})
    # opts: user_id
    conds = []
    conds << "a.user_id = #{opts[:user_id].to_i}" if opts[:user_id]
    conds << opts[:conditions] if opts[:conditions]
    cond = ''
    cond = " AND #{conds.join(' AND ')}" if conds.size > 0
    if cls_name
      cat_ids = self.all_children_ids(:taxonomy => Term.taxonomy_from_class_name(cls_name))
    else
      cat_ids = self.all_children_ids
    end

    contents = Content.find_by_sql("SELECT a.* FROM contents a JOIN contents_terms b ON a.id = b.content_id WHERE b.term_id IN (#{cat_ids.join(',')}) AND a.state = #{Cms::PUBLISHED} #{cond} ORDER BY a.created_on DESC LIMIT 1")
    contents.size > 0 ? contents[0] : nil
  end

  def can_be_destroyed?
    # primera linea es para categorias no de primer nivel
    # segunda es para categorias de primer nivel
     ((self.root_id != self.id && self.contents_count == 0) || \
    self.root_id == self.id && (self.game_id || self.platform_id) && Faction.find_by_code(self.code).nil?)
  end

  def self.taxonomy_from_class_name(cls_name)
    "#{ActiveSupport::Inflector::pluralize(cls_name)}Category"
  end

  # valid opts keys: cls_name
  def contents_count(opts={})
    # TODO perf optimizar mas, si el tag tiene el mismo taxonomy que el solicitado
    raise "cls_name not specified" if self.taxonomy.nil? && opts[:cls_name].nil?
    sql_cond = opts[:conditions] ? " AND #{opts[:conditions]}" : ''
    if opts[:cls_name] != nil
      taxo = self.class.taxonomy_from_class_name(opts[:cls_name])
      User.db_query("SELECT count(*) FROM (SELECT content_id
                                                              FROM contents_terms a
                                                              JOIN terms b on a.term_id = b.id
                                                              JOIN contents on a.content_id = contents.id
                                                             WHERE (((a.term_id IN (#{all_children_ids(:taxonomy => taxo).join(',')})
                                                               AND b.taxonomy = #{User.connection.quote(taxo)})
                                                                OR a.term_id = #{self.id})
                                                                   #{sql_cond})
                                                           GROUP BY content_id
                                                            ) as foo")[0]['count'].to_i

    elsif self.taxonomy
      User.db_query("SELECT count(*) FROM (SELECT content_id
                                                              FROM contents_terms a
                                                              JOIN terms b on a.term_id = b.id
                                                              JOIN contents on a.content_id = contents.id
                                                             WHERE (((a.term_id IN (#{all_children_ids(:taxonomy => self.taxonomy).join(',')})
                                                               AND b.taxonomy = #{User.connection.quote(self.taxonomy)})
                                                                OR a.term_id = #{self.id})
                                                                #{sql_cond})
                                                           GROUP BY content_id
                                                            ) as foo")[0]['count'].to_i
    else # shortcut, show everything
      if self.attributes['contents_count'].nil?
        self.recalculate_counters
        self.reload
        self.attributes['contents_count']
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
      Routing.gmurl(uniq)
      # self.children.each { |child| child.reset_contents}
    end
  end

  # Busca contenidos asociados a este término o a uno de sus hijos
  def find(*args)
    args = _add_cats_ids_cond(*args)
    res = Content.find(*args)

    if res.kind_of?(Array)
      res.uniq.collect { |cont| cont.real_content }
    elsif res
      res.real_content
    end
  end

  def method_missing(method_id, *args)
    begin
      super
    rescue NoMethodError
      if Cms::CONTENTS_WITH_CATEGORIES.include?(ActiveSupport::Inflector::camelize(method_id.to_s))
        TermContentProxy.new(ActiveSupport::Inflector::camelize(method_id.to_s), self)
      elsif Cms::CONTENTS_WITH_CATEGORIES.include?(ActiveSupport::Inflector::camelize(ActiveSupport::Inflector::singularize(method_id.to_s)))
        TermContentProxy.new(ActiveSupport::Inflector::camelize(ActiveSupport::Inflector::singularize(method_id.to_s)), self)
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
    if Cms::CONTENTS_WITH_CATEGORIES.include?(ActiveSupport::Inflector::camelize(method_id.to_s))
      true
    elsif Cms::CONTENTS_WITH_CATEGORIES.include?(ActiveSupport::Inflector::camelize(ActiveSupport::Inflector::singularize(method_id.to_s)))
      true
    else
      super
    end
  end

  # Cuenta imágenes asociadas a esta categoría o a una de sus hijas
  # TODO se puede optimizar usando caches en categorías para images
  def count(*args)
    args = _add_cats_ids_cond(*args)
    opts = args.pop
    opts.delete(:order) if opts[:order]
    args.push(opts)
    if opts[:joins]
      if opts[:conditions] && opts[:conditions].kind_of?(Array)
        opts[:conditions] = ActiveRecord::Base.send( "sanitize_sql_array", opts[:conditions])
      end
      opts[:joins] << " join contents_terms on contents.id = contents_terms.content_id " unless opts[:joins].include?('contents_terms')
      Content.count_by_sql("SELECT count(*) FROM (SELECT contents.id FROM contents #{opts[:joins]} WHERE #{opts[:conditions]} GROUP BY contents.id) AS foo")
    else
      self.contents.count(*args)
    end
  end


  # acepta keys: treemode (true: incluye categorías de hijos)
  def _add_cats_ids_cond(*args)
    @_add_cats_ids_done = true
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

    # si el primer arg es un id caso especial!
    if args.reverse.first.kind_of?(Fixnum)
      nargs = args.reverse
      theid = nargs.pop
      nargs.push(:first)
      raise "find(id) a traves de term sin haber especificado content_type" unless options[:content_type]
      new_cond << " AND #{ActiveSupport::Inflector::tableize(options[:content_type])}.id = #{theid}"
      args = nargs
    end

    if options[:content_type].nil? && options[:content_type_id].nil? && self.taxonomy.to_s.index('Category')
      options[:content_type] = Cms.extract_content_name_from_taxonomy(self.taxonomy)
    end

    if options[:content_type].nil? && options[:content_type_id].nil? && @content_type_mask
      options[:content_type] = @content_type_mask
    end

    if options[:content_type]
      new_cond << " AND contents.content_type_id = #{ContentType.find_by_name(options[:content_type]).id}"
      options[:joins] = "JOIN #{ActiveSupport::Inflector::tableize(options[:content_type])} ON #{ActiveSupport::Inflector::tableize(options[:content_type])}.unique_content_id = contents.id"
    end


    if options[:content_type_id]
      new_cond << " AND contents.content_type_id = #{options[:content_type_id]}"
      ct = ContentType.find(options[:content_type_id])
      options[:joins] = "JOIN #{ActiveSupport::Inflector::tableize(ct.name)} ON #{ActiveSupport::Inflector::tableize(ct.name)}.unique_content_id = contents.id"
      #options[:include] ||= []
      #options[:include] << :contents
    end

    options[:joins] ||= ''
    options[:joins] <<= " JOIN contents_terms on contents.id = contents_terms.content_id "

    options.delete :treemode
    options.delete :content_type
    options.delete :content_type_id

    if options[:conditions].kind_of?(Array)
      options[:conditions][0] = "#{options[:conditions][0]} AND #{new_cond}"
    elsif options[:conditions] then
      options[:conditions] = "#{options[:conditions]} AND #{new_cond}"
    else
      options[:conditions] = "#{new_cond}"
    end

    args.push(options)

    agfirst = args.first
    if agfirst.is_a?(Symbol) && [:drafts, :published, :deleted, :pending].include?(agfirst) then
      options = args.last.is_a?(Hash) ? args.pop : {} # copypasted de extract_options_from_args!(args)
      new_cond = "contents.state = #{Cms.const_get(agfirst.to_s.upcase)}"

      if options[:conditions].kind_of?(Array)
        options[:conditions][0] = "#{options[:conditions][0]} AND #{new_cond} "
      elsif options[:conditions].to_s != '' then
        options[:conditions] = "#{options[:conditions]} AND #{new_cond} "
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
      obj = self.find(:published, :order => 'updated_on DESC', :limit => 1)

      if obj.size > 0 then
        obj = obj[0]
        # no usamos save para no tocar updated_on, created_on porque record_timestamps falla
        self.class.db_query("UPDATE terms SET last_updated_item_id = #{obj.unique_content_id} WHERE id = #{self.id}")
        self.reload
        obj
      else
        self.class.db_query("UPDATE terms SET last_updated_item_id = NULL WHERE id = #{self.id}")
        self.reload
        nil
      end
    else
      self.last_updated_item.real_content
    end
  end

  def random(limit=3)
    cat_ids = self.all_children_ids
    self.class.items_class.find(:all, :conditions => "state = #{Cms::PUBLISHED} and #{ActiveSupport::Inflector.underscore(self.class.name)}_id in (#{cat_ids.join(',')})", :order => 'RANDOM()', :limit => limit)
  end

  def most_popular_authors(opts)
    q_add = opts[:conditions] ? " AND #{opts[:conditions]}" : ''
    opts[:limit] ||= 5
    dbitems = User.db_query("SELECT count(contents.id),
                                    contents.user_id
                              from #{ActiveSupport::Inflector::tableize(opts[:content_type])}
                              JOIN contents on  #{ActiveSupport::Inflector::tableize(opts[:content_type])}.unique_content_id = contents.id
                             WHERE contents.state = #{Cms::PUBLISHED}#{q_add}
                          GROUP BY contents.user_id
                          ORDER BY sum((coalesce(hits_anonymous, 0) + coalesce(hits_registered * 2, 0)+ coalesce(cache_comments_count * 10, 0) + coalesce(cache_rated_times * 20, 0))) desc
                             limit #{opts[:limit]}")
    dbitems.collect { |dbitem| [User.find(dbitem['user_id']), dbitem['count'].to_i] }
  end


  def most_rated_items(opts)
    raise "content_type unspecified" unless opts[:content_type] || opts[:joins]
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
                    WHERE B.term_id IN (#{all_children_ids.join(',')})
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

  def last_updated_items(opts={})
    opts = {:limit => 5, :order => 'updated_on DESC'}.merge(opts)
    self.find(:published, opts)
  end


  def last_updated_children(opts={})
    opts = {:limit => 5}.merge(opts)
    sql_cond = opts[:conditions] ? " AND #{opts[:conditions]}" : ''
    Content.find_by_sql("SELECT *
                           FROM contents
                          WHERE id IN (SELECT last_updated_item_id
                           FROM terms WHERE id IN (SELECT id FROM terms WHERE parent_id = #{self.id})#{sql_cond})
                       ORDER BY updated_on DESC
                          LIMIT #{opts[:limit]}").collect { |c| c.terms.find(:all, :conditions => "1 = 1 #{sql_cond}")[0] }.compact.sort_by { |e| e.name.downcase }
  end


  # TODO tests
  def most_active_users(taxonomy, time_interval='1 month')
	 return all_time_users(taxonomy, time_interval)
  end

  def all_time_users(taxonomy, time_interval='1 month')
    raise "unsupported" unless taxonomy == 'TopicsCategory'

    q_time = time_interval ? " AND created_on > (now() -  '#{time_interval}'::interval)" : ''

	tbl = {}
    User.db_query("SELECT count(*), user_id
		         FROM contents
		        WHERE contents.id in (SELECT content_id
		      					FROM contents_terms
		      				       WHERE term_id IN (#{all_children_ids(:taxonomy => taxonomy).join(',')}))
		  	    #{q_time}
		     GROUP BY user_id HAVING count(*) > 2
		     ORDER BY count(*) DESC").each do |t|
      tbl[t['user_id'].to_i] = {:karma_sum => Karma::KPS_CREATE['Topic'] * t['count'].to_i,
        :topics => t['count'].to_i,
        :comments => 0}
    end

    User.db_query("SELECT count(*), user_id
		         FROM comments
		        WHERE comments.content_id in (SELECT content_id
		      					FROM contents_terms
		      				       WHERE term_id IN (#{all_children_ids(:taxonomy => taxonomy).join(',')}))
		  	    #{q_time}
		     GROUP BY user_id HAVING count(*) > 2
		     ORDER BY count(*) DESC").each do |c|
		puts c
		tbl[c['user_id'].to_i] = {:karma_sum => 0, :topics => 0, :comments => 0} unless tbl[c['user_id'].to_i]
		tbl[c['user_id'].to_i][:karma_sum] += Karma::KPS_CREATE['Comment'] * c['count'].to_i
		tbl[c['user_id'].to_i][:comments] += c['count'].to_i
    end

    first = nil
    second = nil
    third = nil
    fourth = nil
    fifth = nil

    inverted = {}
    tbl.keys.each do |u|
	inverted[tbl[u][:karma_sum]] ||= []
	inverted[tbl[u][:karma_sum]] << [u, tbl[u]]
    end


    inverted.keys.sort.reverse.each do |kps|
        break if fifth

	inverted[kps].each do |row|
            break if fifth

	    if first.nil?
		    first = row
	    elsif second.nil?
		    second = row
	    elsif third.nil?
		    third = row
	    elsif fourth.nil?
		    fourth = row
	    else
		    fifth = row
	    end
	end
    end


    # NOTA: tb contamos comentarios de hace más de 3 meses en el top 3 de comentarios
    # buscamos el total de karma generado por este topic
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

    if fourth
      fourth[1][:relative_pcent] = fourth[1][:karma_sum].to_f / max
      result<< [User.find(fourth[0]), fourth[1]]
    end

    if fifth
      fifth[1][:relative_pcent] = fifth[1][:karma_sum].to_f / max
      result<< [User.find(fifth[0]), fifth[1]]
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


  # TODO PERF
  def set_dummy
    @siblings ||= []
    Term.toplevel(:clan_id => nil).each do |t| @siblings<< t end
  end

  def add_sibling(sibling_term)
    raise "sibling_term must be a term but is a #{sibling_term.class.name}" unless sibling_term.class.name == 'Term'
    @siblings ||= []
    @siblings<< sibling_term
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

  def self.content_types_from_root(root_term)
    raise "Root term isn't really root, bastard!" unless root_term.id == root_term.root_id
    sql_conds = Cms::CATEGORIES_TERMS_CONTENTS.collect { |s| "'#{s}'"}
    if root_term.game_id
      ContentType.find(:all, :conditions => "name in (#{sql_conds.join(',')})", :order => 'lower(name)')
    elsif root_term.platform_id
      ContentType.find(:all, :conditions => "name in (#{sql_conds.join(',')})", :order => 'lower(name)')
    elsif root_term.clan_id
      ContentType.find(:all, :conditions => "name in (#{sql_conds.join(',')})", :order => 'lower(name)')
    elsif root_term.bazar_district_id
      ContentType.find(:all, :conditions => "name in (#{sql_conds.join(',')})", :order => 'lower(name)')
    elsif root_term.clan_id
    else # especial
      ContentType.find(:all, :conditions => "name in (#{sql_conds.join(',')})", :order => 'lower(name)')
    end
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
      #args.push(opts)
      # args = @term._add_cats_ids_cond(*args)

      # opts = args.last.is_a?(Hash) ? args.pop : {}
      if method_id == :count # && opts[:joins]
        opts.delete :joins
        opts.delete :order
      end
      args.push(opts)
      begin
        res = @term.send(method_id, *args)
        res
      rescue ArgumentError
        @term.send(method_id)
      end
    end
  end
end
