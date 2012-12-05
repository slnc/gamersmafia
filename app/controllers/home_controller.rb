# -*- encoding : utf-8 -*-
class HomeController < ApplicationController
  NEWS_PER_PAGE = 20
  VALID_DEFAULT_PORTALS = %w(index comunidad facciones bazar hq anunciante)

  attr_reader :cur_faction

  def index_suicidal
    render :action => 'index_suicidal' #, :layout => 'suicidal'
  end

  def set_tetris
    if user_is_authed
      @user.pref_homepage_mode = "tetris"
    else
      cookies[:homepage_mode] = "tetris"
    end
    redirect_to "/"
  end

  def set_stream
    if user_is_authed
      @user.pref_homepage_mode = "stream"
    else
      cookies[:homepage_mode] = "stream"
    end
    redirect_to "/"
  end

  def tetris
    @home_mode = "tetris"
    render :action => "tetris"
  end

  def stream
    @home_mode = "stream"
    render :action => "stream"
  end

  def index
    if user_is_authed && @user.pref_suicidal == 1
      index_suicidal
      return
    end

    if ((user_is_authed && @user.pref_homepage_mode == 'stream') ||
        (!user_is_authed && cookies[:homepage_mode] == "stream"))
      stream
      return
    else
      tetris
      return
    end

    raise "Deprecated: this shouldn't happen!"
    # TODO(slnc): remove all this once it's not necessary anymore

    #if portal.kind_of?(ClansPortal) then
    #  @home = @portal.home
    #elsif portal.kind_of?(FactionsPortal) then
    #  @home = @portal.home
    #  @cur_faction = Faction.find_by_code(@portal.code) if @cur_faction.nil?
    #elsif portal.kind_of?(BazarDistrictPortal) then
    #  @home = 'distrito'
    #  @bazar_district = BazarDistrict.find_by_slug(portal.code)
    #elsif portal.code == 'gm' && ((!request.env['HTTP_REFERER']) || !(request.env['HTTP_REFERER'].include?('gamersmafia')))
    #  # usamos su preferencia de home
    #  @defopt = current_default_portal
    #  @home = (@defopt.to_s != '') ? @defopt : @portal.home
    #  @home = 'facciones_unknown' if @home == 'facciones'
    #  @home = @portal.home if @defopt == 'index'
    #else
    #  @home = @portal.home
    #end

    #if portal.kind_of?(FactionsPortal) then
    #  @title = "Comunidad española de #{@portal.name}"
    #else
    #  @title = (portal_code == 'gm') ? 'Gamersmafia - Bienvenido a la familia' : @portal.name
    #end

    #render(:action => @home) and return
  end

  #def facciones
  #  if @portal.nil? || !@portal.kind_of?(FactionsPortal) then
  #    @cur_faction = Factions.default_faction_for_user(@user)
  #    @portal = FactionsPortal.find_by_code(@cur_faction.code) if @cur_faction
  #  end

  #  @cur_faction = Faction.find_by_code(@portal.code) if @cur_faction.nil?

  #  if @portal && @portal.class.name == 'FactionsPortal'
  #    render :action => @portal.home
  #  else
  #    render :action => 'facciones_unknown'
  #  end
  #end

  def anunciante
    require_auth_users
    require_authorization(:is_advertiser?)
    @advertisers = @user.users_skills.find(:all, :conditions => "role = 'Advertiser'")
    @advertisers_ids = [0] + @advertisers.collect { |adv| adv.role_data.to_i }
  end
end
