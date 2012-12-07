# -*- encoding : utf-8 -*-
# Este módulo se encarga de añadir funcionalidad a los objetos que se comportan
# como contenidos.
module ActsAsContent
  def self.included(base)
    base.extend AddActsAsContent
  end

  module AddActsAsContent
    def acts_as_content # necesario para registrar los distintos callbacks
      before_save :do_before_save
      plain_text :title if name != 'Image'
      attr_accessor :cur_editor

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
      # Returns a string with the url of the main image associated with this
      # content, if any.
      # TODO integrar limit en opts
      def most_popular_authors(opts={})
        q_add = opts[:conditions] ? " AND #{opts[:conditions]}" : ''
        opts[:limit] ||= 5
        dbitems = User.db_query("SELECT count(id), user_id FROM #{ActiveSupport::Inflector::tableize(self.name)} WHERE state = #{Cms::PUBLISHED}#{q_add} GROUP BY (user_id) ORDER BY sum((coalesce(hits_anonymous, 0) + coalesce(hits_registered * 2, 0)+ coalesce(cache_comments_count * 10, 0) + coalesce(cache_rated_times * 20, 0))) desc limit #{opts[:limit]}")
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

      # Soporte para published.find(:all) find(:drafts) find(:deleted), etc
      def find(*args)
        t_name = ActiveSupport::Inflector::tableize(table_name)
        agfirst = args.first
        if agfirst.is_a?(Symbol) && [:drafts, :published, :deleted, :pending].include?(agfirst) then
          options = args.last.is_a?(Hash) ? args.pop : {}  # copypasted de extract_options_from_args!(args)
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
            options = args.last.is_a?(Hash) ? args.pop : {}  # copypasted de extract_options_from_args!(args)
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

      if !Cms::DONT_PARSE_IMAGES_OF_CONTENTS.include?(self.type) then
        for d in Cms::WYSIWYG_ATTRIBUTES[self.type]
          attrs[d] = Cms::parse_images(
              self.attributes[d],
              "#{self.type.downcase}/#{self.id % 1000}/#{self.id}")
        end
      end

      self.update_attributes(attrs)
    end

    def terms=(new_terms)
      @_terms_to_add ||= []
      new_terms = [new_terms] unless new_terms.kind_of?(Array)
      @_terms_to_add += new_terms
    end

    def get_game_id
      if Cms::CONTENTS_WITH_CATEGORIES.include?(self.type) then
        maincat = self.main_category
        return unless maincat
        tld_code = maincat.root.code
        g = Game.find_by_slug(tld_code)
        g.id if g
      end
    end

    def get_my_gaming_platform_id
      if Cms::CONTENTS_WITH_CATEGORIES.include?(self.type) then
        maincat = self.main_category
        return unless maincat
        tld_code = maincat.root.code
        p = GamingPlatform.find_by_slug(tld_code)
        p.id if p
      end
    end

    def get_my_bazar_district_id
      if Cms::CONTENTS_WITH_CATEGORIES.include?(self.type) then
        maincat = self.main_category
        return unless maincat
        tld_code = maincat.root.code
        p = BazarDistrict.find_by_slug(tld_code)
        p.id if p
      end
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

    def my_faction
      if self.main_category.nil?
        Rails.logger.warn("No main_category found for #{self}")
        raise ActiveRecord::RecordNotFound
      end
      Faction.find_by_name(self.main_category.root.name)
    end

    def resolve_html_hid
      if (self.respond_to? 'title')
        self.title
      elsif self.respond_to? 'name'
        self.name
      elsif self.type == 'Image' && self.file
        "<img src=\"/cache/thumbnails/f/85x60/#{self.file}\" />"
      else
        self.id.to_s
      end
    end

    # Devuelve los portales en los que este contenido se muestra.
    # TODO esto no es correcto
    def get_related_portals
      if self.respond_to?(:clan_id) && self.clan_id && self.type != 'RecruitmentAd'
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
