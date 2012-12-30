# -*- encoding : utf-8 -*-
module Routing
  def self.url_for_content_onlyurl(object)
    # TODO quitar esto y usar gmurl
    href = Cms.translate_content_name(object.class.name)
    href = href.normalize
    if href == 'topics' then
      "/foros/topic/#{object.id}"
    elsif href == 'preguntas' then
      "/respuestas/show/#{object.id}"
    elsif href == 'anuncios-de-reclutamiento' then
      "/reclutamiento/anuncio/#{object.id}"
    elsif object.class.name == 'Blogentry' then
      "/blogs/#{object.user.login}/#{object.id}"
    elsif object.class.name == 'Event'
      cm = CompetitionsMatch.find_by_event_id(object.id)
      if cm
        "/competiciones/partida/#{cm.id}"
      else
        "/#{href}/show/#{object.id}"
      end
    elsif object.class.name == 'Coverage' then
      "/coverages/show/#{object.id}"
    else
      "/#{href}/show/#{object.id}"
    end
  end

  def self.gmurl(object, opts={})
    cls_name = object.class.name
    if cls_name.index('Category')
      # DEPRECATED taxonomies
      href = Cms::translate_content_name(ActiveSupport::Inflector::singularize(cls_name.gsub('Category', '')))
      href = href.normalize
      case href
        when 'topics'
        href = "foros/forum"
        when 'preguntas'
        href = "respuestas/categoria"
        when 'anuncios-de-reclutamiento'
        href = 'reclutamiento'
      end
      "/#{href}/#{object.id}"
    elsif cls_name == 'Comment'
      base_url = self.gmurl(object.content)
      page = object.comment_page
      "#{base_url}?page=#{page}#comment#{object.id}"
    elsif cls_name == 'Term'
      if %w(BazarDistrict Homepage).include?(object.taxonomy)
        "http://#{object.slug}.#{App.domain}"

      elsif object.taxonomy == 'Game'
        if Faction.find_by_code(object.slug)
          "http://#{object.slug}.#{App.domain}"
        else
          "/juegos/#{Game.find_by_name(object.name).id}"
        end

      elsif object.taxonomy == 'GamingPlatform'
        if Faction.find_by_code(object.slug)
          "http://#{object.slug}.#{App.domain}"
        else
          "/plataformas/#{GamingPlatform.find_by_name(object.name).id}"
        end

      elsif object.taxonomy == 'Clan'
        "/clanes/show/#{object.id}"

      elsif object.taxonomy == 'ContentsTag'
        "/tags/#{object.slug}"

      else
        opts[:taxonomy] = object.taxonomy unless opts[:taxonomy]
        if opts[:taxonomy].index('Category')
          href = Cms::translate_content_name(ActiveSupport::Inflector::singularize(opts[:taxonomy].gsub('Category', '')))
          href = href.normalize
          case href
            when 'topics'
            href = "foros/forum"
            when 'preguntas'
            href = "respuestas/categoria"
            when 'anuncios-de-reclutamiento'
            href = 'reclutamiento'
          end
          dom = get_domain_of_root_term(object.root)
          "http://#{dom}/#{href}/#{object.id}"
        else
          raise "gmurl for term with unrecognized taxonomy '#{opts[:taxonomy]}'"
        end
      end
    elsif cls_name == 'Faction'
      "http://#{object.code}.#{App.domain}/"
    elsif cls_name == 'Clan'
      "http://#{App.domain}/clanes/clan/#{object.id}"
    elsif %w(Competition League Ladder Tournament).include?(cls_name)
      "http://arena.#{App.domain}/competiciones/show/#{object.id}"
    elsif %w(Friend User).include?(cls_name)
      # TODO the right way would be URI.escape('b@rto',Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")) but we only have problems with @ right now so I hack it
      "http://#{App.domain}/miembros/#{object.login.gsub('@', '%40')}"
    elsif nil
      raise "Nil object can't have url"
    else
      Routing.url_for_content_onlyurl(object)
    end
  end
end
