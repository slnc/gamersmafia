# Este módulo se encarga de añadir funcionalidad a los objetos que se comportan
# como contenidos.
module ActsAsContent
  def self.included(base)
    base.extend AddActsAsContent
  end

  module AddActsAsContent
    def acts_as_content # necesario para registrar los distintos callbacks
      after_create :do_after_create
      after_save :do_after_save
      after_update :do_after_update

      after_destroy :do_after_destroy

      #belongs_to :unique_content, :class_name => 'Content'

      scope :draft, :conditions => "state = #{Cms::DRAFT}"
      scope :pending, :conditions => "state = #{Cms::PENDING}"
      scope :published, :conditions => "state = #{Cms::PUBLISHED}"
      scope :deleted, :conditions => "state = #{Cms::DELETED}"
      scope :onhold, :conditions => "state = #{Cms::ONHOLD}"

      scope :in_term, lambda { |term| { :conditions => ["unique_content_id IN (SELECT content_id FROM contents_terms WHERE term_id = ?)", term.id] }}
      scope :in_term_tree, lambda { |term| { :conditions => ["unique_content_id IN (SELECT content_id FROM contents_terms WHERE term_id IN (?))", term.all_children_ids] }}
      scope :in_portal, lambda { |portal|
        if portal.id == -1
          {}
        else
          taxonomy = "#{ActiveSupport::Inflector.pluralize(self.name)}Category"
          { :conditions => ["unique_content_id IN (SELECT content_id FROM contents_terms WHERE term_id IN (?))", portal.terms_ids(taxonomy)] }
        end
      }

      scope :most_rated, :conditions => 'cache_rated_times > 1', :order => 'coalesce(cache_weighted_rank, 0) DESC'
      scope :most_popular, :conditions => "cache_rated_times > 1",
        :order => '(coalesce(hits_anonymous, 0) + coalesce(hits_registered * 2, 0)+ coalesce(cache_comments_count * 10, 0) + coalesce(cache_rated_times * 20, 0)) DESC'

      validates_presence_of :user
      before_create { |m| m.log = nil; m.log_action('creado', m.user.login) }
      before_save :do_before_save
      before_destroy :do_before_destroy
      plain_text :title if name != 'Image'
      belongs_to :user
      # belongs_to :editor, :class_name => 'User', :foreign_key => 'approved_by_user_id'
      serialize :log
      attr_accessor :cur_editor

      before_save do |m|
        if !m.log_changed?
          if m.cur_editor
            m.cur_editor = User.find(m.cur_editor) if m.cur_editor.kind_of?(Fixnum)
            m.log_action('modificado', m.cur_editor)
          end
        end

        if m.attributes[:terms]
          m.attributes[:terms] = [m.attributes[:terms]] unless m.attributes[:terms].kind_of(Array)
          @_terms_to_add = m.attributes[:terms]
          m.attributes.delete :terms
        end
        true
      end

      class_eval <<-END
        include ActsAsContent::InstanceMethods
      END
    end

  end

  module InstanceMethods
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      # TODO integrar limit en opts
      def most_popular_authors(opts={})
        q_add = opts[:conditions] ? " AND #{opts[:conditions]}" : ''
        opts[:limit] ||= 5
        dbitems = User.db_query("SELECT count(id), user_id from #{ActiveSupport::Inflector::tableize(self.name)} WHERE state = #{Cms::PUBLISHED}#{q_add} GROUP BY (user_id) ORDER BY sum((coalesce(hits_anonymous, 0) + coalesce(hits_registered * 2, 0)+ coalesce(cache_comments_count * 10, 0) + coalesce(cache_rated_times * 20, 0))) desc limit #{opts[:limit]}")
        dbitems.collect { |dbitem| [User.find(dbitem['user_id']), dbitem['count'].to_i] }
      end


      # TODO atención, estamos mostrando contenidos publicados únicamente, verdad?
      # devuelve los contenidos publicados más populares (considera hits, comentarios y veces valorado)
      def most_popular(opts={})
        q_add = opts[:conditions] ? " AND #{opts[:conditions]}" : ''
        opts[:limit] ||= 3

        # TODO el state aquí y abajo sobra, no?
        self.find(:all, :conditions => "state = #{Cms::PUBLISHED}#{q_add}", :order => '(coalesce(hits_anonymous, 0) + coalesce(hits_registered * 2, 0)+ coalesce(cache_comments_count * 10, 0) + coalesce(cache_rated_times * 20, 0)) DESC', :limit => opts[:limit])
      end

      # devuelve los contenidos publicados mejor valorados
      # TODO integrar limit en opts
      def best_rated(opts={})
        opts = {:limit => 5}.merge(opts)
        q_add = opts[:conditions] ? " AND #{opts[:conditions]}" : ''

        self.published.find(:all, :conditions => "cache_rated_times > 1#{q_add}", :order => 'coalesce(cache_weighted_rank, 0) DESC, (hits_anonymous + hits_registered) DESC', :limit => opts[:limit])
      end

      def pending
        self.find(:all, :conditions => "#{'clan_id IS NULL AND' if respond_to?(:clan_id)} state = #{Cms::PENDING}", :order => 'created_on ASC')
      end

      def published_between(d1, d2)
        self.find(:all,
                  :conditions => "state = #{Cms::PUBLISHED}
                                    AND created_on
                                  BETWEEN to_timestamp('#{d1.strftime("%Y%m%d%H%M%S")}', 'YYYYMMDDHH24MISS')
                                      AND to_timestamp('#{d2.strftime("%Y%m%d%H%M%S")}', 'YYYYMMDDHH24MISS')",
        :order => 'created_on DESC')
      end

      # Soporte para published.find(:all) find(:drafts) find(:deleted), etc
      def find(*args)
        t_name = ActiveSupport::Inflector::tableize(table_name)
        agfirst = args.first
        if agfirst.is_a?(Symbol) && [:drafts, :published, :deleted, :pending].include?(agfirst) then
          options = args.last.is_a?(Hash) ? args.pop : {} # copypasted de extract_options_from_args!(args)
          new_cond = "#{t_name}.state = #{Cms.const_get(agfirst.to_s.upcase)}"

          if options[:conditions].kind_of?(Array)
            options[:conditions][0]<< " AND #{new_cond} "
          elsif options[:conditions].to_s != '' then
            options[:conditions]<< " AND #{new_cond} "
          else
            options[:conditions] = new_cond
          end

          options[:order] = "#{t_name}.created_on DESC" unless options[:order]
          args[0] = :all
          args.push(options)
        end
        super(*args)
      end


      def count(*args)
        if args.size > 0
          agfirst = args.first
          if agfirst.is_a?(Symbol) && [:drafts, :published, :deleted, :pending].include?(agfirst) then
            options = args.last.is_a?(Hash) ? args.pop : {} # copypasted de extract_options_from_args!(args)
            args.delete_at(0)
            new_cond = "state = #{Cms.const_get(agfirst.to_s.upcase)}"
            if options[:conditions].kind_of?(Array)
              options[:conditions][0]<< " AND #{new_cond}"
            elsif options[:conditions] then
              options[:conditions]<< " AND #{new_cond}"
            else
              options[:conditions] = new_cond
            end
            args[0] = options
          end
        end
        super(*args)
      end
    end

    # Procesa los campos wysiwyg y manipula las imágenes en caso de
    # encontrarlas: se las descarga si son remotas y crea thumbnails si están
    # resizeadas y no tienen ya un link alrededor.
    def process_wysiwyg_fields
      attrs = {}

      if !Cms::DONT_PARSE_IMAGES_OF_CONTENTS.include?(self.class.name) then
        for d in Cms::WYSIWYG_ATTRIBUTES[self.class.name]
          attrs[d] = Cms::parse_images(self.attributes[d], "#{self.class.name.downcase}/#{self.id % 1000}/#{self.id}")
        end
      end

      self.update_attributes(attrs)
    end

    def log_action(action_name, author=nil, reason=nil)
      self.log ||= []
      if !(self.log.size > 0 && self.log[-1][0] == action_name && self.log[-1][2] > 5.seconds.ago) # no meter entradas repetidas
        self.log<< [action_name, author.to_s, Time.now, reason]
      end
    end

    def closed_by_user
      return nil unless self.closed?
      self.log.reverse.each do |lentry|
        if lentry[0] == 'cerrado'
          return User.find_by_login(lentry[1])
        end
      end
    end

    def reason_to_close
      return nil unless self.closed?
      self.log.reverse.each do |lentry|
        if lentry[0] == 'cerrado'
          return lentry[3]
        end
      end
    end

    def close(user, reason)
      return if self.closed?
      self.closed = true
      self.log_action('cerrado', user, reason)
      self.save
    end

    def reopen(user)
      return unless self.closed?
      self.closed = false
      self.log_action('reabierto', user)
      self.save
    end


    def recover(user)
      self.state = Cms::PUBLISHED
      self.log_action('recuperado', user)
      self.save
      self.add_karma if is_public?
    end

    def do_after_save
      return false if self.unique_content_id.nil?
      if @_terms_to_add
        @_terms_to_add.each do |tid|
          Term.find(tid).link(self.unique_content)
        end
        @_terms_to_add = []
        if self.unique_content_id
          uniq = self.unique_content
          uniq.url = nil
          Routing.gmurl(uniq)
        end
      end

      true
    end

    def do_after_create
      create_my_unique_content
      # Lo añadimos al tracker del usuario
      Users.add_to_tracker(self.user, self.unique_content)
    end

    def terms=(new_terms)
      @_terms_to_add ||= []
      new_terms = [new_terms] unless new_terms.kind_of?(Array)
      @_terms_to_add += new_terms
    end

    def unique_content
      @_cache_unique_content ||= Content.find(self.unique_content_id) if self.unique_content_id
    end

    def root_terms
      self.unique_content.root_terms
    end

    def root_terms_ids=(arg)
      self.unique_content.root_terms_ids=(arg)
      self.unique_content.reload # necesario porque no se borra la cache del objeto de terms
    end

    # arg[0] arg
    # arg[1] taxonomy
    def categories_terms_ids=(arg)
      self.unique_content.categories_terms_ids=(arg)
      self.unique_content.reload # necesario porque no se borra la cache del objeto de terms
    end

    def root_terms_add_ids(arg)
      self.unique_content.root_terms_add_ids(arg)
      self.unique_content.reload # necesario porque no se borra la cache del objeto de terms
    end

    def categories_terms
      self.unique_content.categories_terms
    end

    def categories_terms_add_ids(arg, taxonomy)
      self.unique_content.categories_terms_add_ids(arg, taxonomy)
      self.unique_content.reload # necesario porque no se borra la cache del objeto de terms
    end

    def do_before_save
      if self.respond_to?(:source) && self.source
        if self.source.strip == ''
          self.source = nil
        else
          if !(Cms::URL_REGEXP =~ self.source)
            self.errors.add('source', 'URL incorrecta')
            return false
          end
        end
      end

      attrs = {}
      # TODO llamar específicamente a esta función para actualizar las imágenes
      if !Cms::DONT_PARSE_IMAGES_OF_CONTENTS.include?(self.class.name) and self.record_timestamps then
        tmpid = id
        tmpid = 0 if self.id.nil?
        for d in Cms::WYSIWYG_ATTRIBUTES[self.class.name]
          attrs[d] = Cms::parse_images(self.attributes[d], "#{self.class.name.downcase}/#{tmpid % 1000}")
        end

        self.attributes = attrs
      end

      # TODO más inteligencia?
      # creamos versión si se ha cambiado title, description, main o el campo de
      # categoría
      # self.class.find(self.id)
      if !self.new_record? && self.id
        oldv = self.class.find(self.id).attributes
        copy = false
        %w(title description main).each do |attr|
          if self.respond_to?(attr) && oldv[attr] != self.send(attr)
            copy = true
            break
          end
        end

        self.unique_content.contents_versions.create(:data => oldv) if copy
      end

      if self.respond_to?(:title)
        if self.title.to_s.strip == ''
          self.errors.add('title', 'El título no puede estar en blanco')
          return false
        else

          self.title = self.title.downcase.titleize if self.title.upcase == self.title && self.title.size > 10
          self.title = self.title[0..-2] if self.title[-1..-1] == '.'
          true
        end
      end

      true
    end

    def do_after_update
      update_content
    end

    def do_after_destroy
      # decrement_items_count
    end

    def do_before_destroy
      prepare_destruction
    end


    def terms(*args)
      self.unique_content.send(:terms, *args)
    end

    def get_game_id
      if Cms::CONTENTS_WITH_CATEGORIES.include?(self.class.name) then
        maincat = self.main_category
        return unless maincat
        tld_code = maincat.root.code
        g = Game.find_by_code(tld_code)
        g.id if g
      end
    end

    def get_my_platform_id
      if Cms::CONTENTS_WITH_CATEGORIES.include?(self.class.name) then
        maincat = self.main_category
        return unless maincat
        tld_code = maincat.root.code
        p = Platform.find_by_code(tld_code)
        p.id if p
      end
    end

    def get_my_bazar_district_id
      if Cms::CONTENTS_WITH_CATEGORIES.include?(self.class.name) then
        maincat = self.main_category
        return unless maincat
        tld_code = maincat.root.code
        p = BazarDistrict.find_by_code(tld_code)
        p.id if p
      end
    end

    def comments_ids
      User.db_query("SELECT id FROM comments WHERE content_id = #{self.unique_content.id}").collect! { |dbc| dbc['id']}
    end

    def change_authorship(new_user, editor)
      raise ValueError if !new_user.kind_of?(User)
      return if new_user.id == self.user_id

      self.del_karma if is_public?

      # TODO ya no :p hacemos esto para no triggerear record_timestamps
      # self.class.db_query("UPDATE #{ActiveSupport::Inflector::tableize(self.class.name)} SET user_id = #{new_user.id} WHERE id = #{self.id}")
      # self.reload
      self.user_id = new_user.id
      self.user = new_user # necesario hacer ambos cambios por si ya se ha cargado self.user antes
      self.log_action('cambiada autoría', editor)
      self.save

      self.add_karma if is_public?
    end

    # Devuelve un array de todos los atributos de este objeto que son únicos
    def unique_attributes
      out = {}
      self.attributes.each do |k,v|
        next if [:id, :unique_content_id, :terms].include?(k.to_sym)
        out[k.to_sym] = v unless Cms::COMMON_CLASS_ATTRIBUTES.include?(k.to_sym)
      end
      out
    end

    def last_comment
      return self.unique_content.comments.find(:first, :conditions => 'deleted = \'f\'', :order => 'created_on desc')
    end

    def has_category?
      Cms::CONTENTS_WITH_CATEGORIES.include?(self.class.name)
    end

    # Devuelve la primera categoría asociada a este contenido
    def main_category
      # DEPRECATED
      uniq = self.unique_content
      # para que haya un main_category a la hora de guardar el contenido
      if uniq.nil? # no linked_terms yet, perhaps given?
        return nil if @_terms_to_add.nil? || (@_terms_to_add.kind_of?(Array) && @_terms_to_add.size == 0)
        cats = @_terms_to_add.collect { |tid| Term.find(tid) }
      else
        if Cms::ROOT_TERMS_CONTENTS.include?(self.class.name)
          cats = uniq.linked_terms('NULL')
        else
          cats = uniq.linked_terms("#{ActiveSupport::Inflector::pluralize(self.class.name)}Category")
        end
      end

      if cats.size > 0
        cats[0]
      else
        self.unique_content.linked_terms('NULL')[0]
      end
    end

    def my_faction
      Faction.find_by_name(self.main_category.root.name)
    end

    def update_content
      if self.record_timestamps == true then
        uniq = self.unique_content

        if uniq then
          uniq.state = self.state
          uniq.source = self.source if self.respond_to?(:source)
          uniq.closed = self.closed
          uniq.save # refresh updated_on
        end
      end
    end

    def reload
      @_cache_unique_content = nil
      @_cache_unique_content_type = nil
      super
    end

    # funciones para crear contenido único
    def OLD_unique_content
      @_cache_unique_content ||= self.unique_content_type.contents.find(:first, :conditions => "external_id = #{self.id}")
    end

    def unique_content_type
      # TODO arreglar esto, guardar nombre de clase y listo
      @_cache_unique_content_type ||= ContentType.find_by_name(self.class.name)
    end

    # no llamarlo create_unique_content pq rails es demasiado listo
    def create_my_unique_content
      myctype = ContentType.find(:first, :conditions => "name = '#{self.class.name}'")
      base_opts = { :content_type_id => myctype.id,
                  :external_id => self.id,
                  :name => self.resolve_hid,
                  :updated_on => self.created_on,
                  :state => self.state
      }
      base_opts.merge!({:clan_id => self.clan_id}) if self.respond_to? :clan_id
      base_opts.merge!({:source => self.source}) if self.respond_to? :source
      c = Content.create(base_opts)

      raise "error creating content!" if c.new_record?

      self.unique_content_id = c.id
      User.db_query("UPDATE #{ActiveSupport::Inflector::tableize(self.class.name)} SET unique_content_id = #{c.id} WHERE id = #{self.id}")

      # añadimos karma si es un contenido que no necesita ser moderado
      add_karma if Cms::NO_MODERATION_NEEDED_CONTENTS.include?(self.class.name)
    end

    def delete_unique_content
      self.unique_content.destroy
    end

    # this content's contributed karma
    def karma
      Karma.contents_karma(self)
    end

    def add_karma
      Karma.add_karma_after_content_is_published(self)
    end

    def del_karma
      Karma.del_karma_after_content_is_unpublished(self)
    end

    def change_state(new_state, editor)
      return if new_state == self.state || self.invalid?
      raise AccessDenied unless Cms::user_can_edit_content?(editor, self)
      case new_state
        when Cms::DRAFT:
        raise 'impossible'
        when Cms::PENDING:
        raise 'impossible' unless self.state == Cms::DRAFT
        self.log_action('enviado a cola de moderación', editor)
        when Cms::PUBLISHED:
        raise "impossible, current_state #{self.id} = #{self.state}" unless [Cms::PENDING, Cms::DELETED, Cms::ONHOLD, Cms::DRAFT].include?(self.state)
        self.created_on = Time.now if self.state == Cms::PENDING # solo le cambiamos la hora si el estado anterior era cola de moderación
        self.log_action('publicado', editor)
        add_karma
        self.unique_content.tracker_items.each do |ti|
          ti.lastseen_on = Time.now
          ti.save
        end

        # Update tracker_items so they don't figure as updated
        when Cms::DELETED:
        raise 'impossible' unless [Cms::PENDING, Cms::PUBLISHED, Cms::ONHOLD, Cms::DRAFT].include?(self.state)
        self.log_action('borrado', editor)
        del_karma if self.state == Cms::PUBLISHED
        when Cms::ONHOLD:
        raise 'impossible' unless [Cms::PUBLISHED, Cms::DELETED, Cms::ONHOLD].include?(self.state)
        self.log_action('movido a espera', editor)
        del_karma if self.state == Cms::PUBLISHED
      else
        raise 'unimplemented'
      end
      self.state = new_state
      self.save # TODO y si falla qué debería hacer change_state?
    end

    def rating
      # devuelve el rating del contenido
      if (self.cache_rating.nil? and self.cache_rated_times.nil?) or (self.cache_rating.nil? and self.cache_rated_times >= 2) then
        self.cache_rating = Content.db_query("SELECT avg(rating) from content_ratings where content_id = #{self.unique_content.id}")[0]['avg']
        self.cache_rated_times = Content.db_query("SELECT count(id) from content_ratings where content_id = #{self.unique_content.id}")[0]['count']
        self.cache_rating = 0 if self.cache_rating.nil?


        # imdb formula
        # r = average for the movie (mean) = (Rating)
        # v = number of votes for the movie = (votes)
        # m = minimum votes required to be listed in the Top 250 (currently 1250)
        # c = the mean vote across the whole report (currently 6.8)
        r = self.cache_rating.to_f
        v = self.cache_rated_times.to_f

        # cogemos el numero de votos como el valor del 1er cuartil ordenando la
        # lista de contenidos por votos asc
        # calculamos "m"
        if Cms::CONTENTS_WITH_CATEGORIES.include?(self.class.name) then
          return 0 if self.main_category.nil?# TODO hack temporal
          total = self.main_category.root.count(:content_type => self.class.name)
          # TODO esto debería ir en term
          q = "SELECT content_id
                 FROM contents
                 JOIN contents_terms ON contents.id = contents_terms.content_id
                WHERE contents.state = #{Cms::PUBLISHED}
                  AND term_id IN (#{self.main_category.root.all_children_ids(:content_type => self.class.name).join(',')})"

          contents_ids = User.db_query(q).collect { |dbr| dbr['content_id'] }

          q = "AND unique_content_id IN (#{contents_ids.join(',')})"
        else
          q = ''
          total = self.class.count(:conditions => "state = #{Cms::PUBLISHED} #{q}")
        end

        dbm = User.db_query("SELECT cache_rated_times
                         FROM #{ActiveSupport::Inflector::tableize(self.class.name)}
                        WHERE state = #{Cms::PUBLISHED} #{q}
                          AND cache_rated_times > 0
                     ORDER BY cache_rated_times LIMIT 1 OFFSET #{(total/100*25 + 0.5).to_i}")
        if dbm.size > 0 then
          m = dbm[0]['cache_rated_times'].to_i
        else
          m = 2
        end

        c = get_mean_vote(m)
        self.cache_weighted_rank = (v / (v+m)) * r + (m / (v+m)) * c

        self.update_without_timestamping
      end

      if self.cache_rated_times < 2 then
        [nil, '<2']
      else
        [self.cache_rating, self.cache_rated_times]
      end
    end

    def get_mean_vote(m)
      # calcula el voto medio para un contenido dependiendo de si tiene categoría o no
      # asumo que cada contenido y cada facción tiene su propia media
      if Cms::CONTENTS_WITH_CATEGORIES.include?(self.class.name) then
        return 0 if self.main_category.nil?# TODO hack temporal
        # cat_ids = self.main_category.root.all_children_ids
        # TODO esto deberia ir en Term

        contents_ids = User.db_query("SELECT content_id
                                          FROM contents
                                          JOIN contents_terms ON contents.id = contents_terms.content_id
                                         WHERE contents.state = #{Cms::PUBLISHED}
                                           AND term_id IN (#{self.main_category.root.all_children_ids(:content_type => self.class.name).join(',')})").collect { |dbr| dbr['content_id'] }

        mean = User.db_query("SELECT avg(cache_rating)
                                FROM #{ActiveSupport::Inflector::tableize(self.class.name)}
                               WHERE cache_rating is not null
                                 AND cache_rated_times >= #{m}
                                 AND unique_content_id IN (#{contents_ids.join(',')})")[0]['avg'].to_f
      else
        mean = User.db_query("SELECT avg(cache_rating)
                                FROM #{ActiveSupport::Inflector::tableize(self.class.name)}
                               WHERE cache_rating is not null
                                 AND cache_rated_times >= #{m}")[0]['avg'].to_f
      end
    end

    def clear_rating_cache
      self.class.db_query("UPDATE #{ActiveSupport::Inflector::tableize(self.class.name)}
                              SET cache_rating = NULL,
                                  cache_rated_times = NULL,
                                  cache_weighted_rank = NULL WHERE id = #{self.id}")
      self.cache_rating = nil
      self.cache_rated_times = nil
      self.cache_weighted_rank = nil
      self.rating # TODO PERF
    end

    def resolve_hid
      if (self.respond_to? 'title') then
        title = self.title
      elsif self.respond_to? 'name' then
        title = self.name
      elsif self.class.name == 'Image' and self.file
        title = File.basename(self.file)
      else
        title = self.id.to_s
      end

      return title
    end

    def resolve_html_hid
      if (self.respond_to? 'title') then
        self.title
      elsif self.respond_to? 'name' then
        self.name
      elsif self.class.name == 'Image' and self.file
        "<img src=\"/cache/thumbnails/f/85x60/#{self.file}\" />"
      else
        self.id.to_s
      end
    end

    def hit_anon
      self.class.increment_counter('hits_anonymous', self.id)
    end

    def hit_reg(user)
      self.class.increment_counter('hits_registered', self.id)

      uniq = self.unique_content
      # si el usuario no tiene un elemento del tracker para este contenido lo creamos
      tracker_item = TrackerItem.find(:first, :conditions => ['user_id = ? and content_id = ?', user.id, self.unique_content.id])

      if not tracker_item then
        tracker_item = TrackerItem.new(:user_id => user.id, :content_id => uniq.id)
      end

      tracker_item.lastseen_on = Time.now

      begin
        tracker_item.save
        cr = ContentsRecommendation.find(:first, :conditions => ['receiver_user_id = ? AND content_id = ? AND seen_on IS NULL', user.id, uniq.id])
        cr.mark_seen if cr
      rescue ActiveRecord::StatementInvalid:
        # try again, maybe overloaded
        TrackerItem.find(:first, :conditions => ['user_id = ? and content_id = ?', user.id, uniq.id])
      end
    end


    def deny_without_reason(editor)
      raise 'DEPRECATED'
      self.mark_as_deleted(editor) if self.state == Cms::PENDING
    end

    def deny(reason, editor)
      raise 'DEPRECATED'
      if self.state == Cms::PENDING
        self.mark_as_deleted(editor)
        reason.strip!

        if not reason.empty? then
          message = Message.new({:title => 'Contenido denegado', :user_id_from => editor.id, :user_id_to => self.user_id, :message => "El contenido \"#{self.resolve_hid}\" (#{self.unique_content.content_type.name}) ha sido denegado. Razón: [quote]#{reason}[/quote]"})
          message.save
        end
      end
    end


    # TODO DEPRECATED
    def mark_as_deleted(cur_editor=nil)
      raise 'DEPRECATED'
      change_state(Cms::DELETED, cur_editor)
    end

    def prepare_destruction
      self.unique_content.destroy

      if Cms::NO_MODERATION_NEEDED_CONTENTS.include?(self.class.name) or (self.state == Cms::PUBLISHED) then # el elemento estaba publicado o era un tópic, quitamos karma
        del_karma
      end
    end

    def is_locked_for_user?(user)
      self.unique_content.locked_for_user?(user)
    end

    def lock(user)
      self.unique_content.lock(user)
    end

    def cur_lock
      self.unique_content.cur_lock
    end

    def is_public?
      self.state == Cms::PUBLISHED
    end

    # Devuelve los portales en los que este contenido se muestra.
    # TODO esto no es correcto
    def get_related_portals
      if self.respond_to?(:clan_id) && self.clan_id && self.class.name != 'RecruitmentAd'
        [ClansPortal.find_by_clan_id(self.clan_id)]
      else
        portals = [GmPortal.new, ArenaPortal.new, BazarPortal.new]
        f = Organizations.find_by_content(self)
        if f.nil? then # No es un contenido de facción o es de categoría gm/otros TODO esto no usarlo con caches, madre del amor hermoso
          portals += Portal.find(:all, :conditions => 'type <> \'ClansPortal\'')
        elsif f.class.name == 'Faction'
          # TODO plataforma PC va a fallar
          portals += Portal.find(:all, :conditions => ['id in (SELECT portal_id from factions_portals where faction_id = ?)', f.id])
        elsif f.class.name == 'BazarDistrict'
          portals += [Portal.find_by_code(f.code)]
        end
        portals
      end
    end
  end
end

ActiveRecord::Base.send(:include, ActsAsContent)
