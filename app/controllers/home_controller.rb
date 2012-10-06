# -*- encoding : utf-8 -*-
class HomeController < ApplicationController
  NEWS_PER_PAGE = 20
  VALID_DEFAULT_PORTALS = %w(index comunidad facciones bazar arena hq anunciante)

  helper :competiciones

  def index_h5
    @title = "Gamersmafia h5"
    render :action => 'index_h5', :layout => 'h5'
  end

  def index_mobile
    render :action => 'index_mobile', :layout => 'mobile'
  end

  def index
    if self.mobile_device?
      self.index_mobile
      return
    end

    if params[:h5]
      index_h5
      return
    end

    if portal.kind_of?(ClansPortal) then
      @home = @portal.home
    elsif portal.kind_of?(FactionsPortal) then
      @home = @portal.home
      @cur_faction = Faction.find_by_code(@portal.code) if @cur_faction.nil?
      @active_sawmode = 'facciones'
    elsif portal.kind_of?(BazarDistrictPortal) then
      @home = 'distrito'
      @bazar_district = BazarDistrict.find_by_code(portal.code)
      @active_sawmode = 'bazar'
    elsif portal.code == 'gm' && ((!request.env['HTTP_REFERER']) || !(request.env['HTTP_REFERER'].include?('gamersmafia')))
      # usamos su preferencia de home
      @defopt = current_default_portal
      @home = (@defopt.to_s != '') ? @defopt : @portal.home
      @home = 'facciones_unknown' if @home == 'facciones'
      @home = @portal.home if @defopt == 'index'
    else
      @home = @portal.home
    end

    @active_sawmode = @home if @active_sawmode.nil? && VALID_DEFAULT_PORTALS.include?(@home)
    if portal.kind_of?(FactionsPortal) then
      @title = "Comunidad española de #{@portal.name}"
    else
      @title = (portal_code == 'gm') ? 'Gamersmafia - Bienvenido a la familia' : @portal.name
    end

    render(:action => @home) and return
  end

  def comunidad
    @active_sawmode = 'comunidad'
    #index
  end

  attr_reader :cur_faction

  def facciones
    @active_sawmode = 'facciones'
    if @portal.nil? || !@portal.kind_of?(FactionsPortal) then
      @cur_faction = Factions.default_faction_for_user(@user)
      @portal = FactionsPortal.find_by_code(@cur_faction.code) if @cur_faction
    end

    @cur_faction = Faction.find_by_code(@portal.code) if @cur_faction.nil?

    if @portal && @portal.class.name == 'FactionsPortal'
      render :action => @portal.home
    else
      render :action => 'facciones_unknown'
      #controller => '/facciones', :action => 'index'
    end
    #index
  end

  def foros
    @active_sawmode = 'foros'
    #index
  end

  def bazar
    @active_sawmode = 'bazar'
    @title = @portal.name
    #index
    render :action => 'bazar'
  end

  def arena
    @active_sawmode = 'arena'
    render :action => 'arena'
  end

  def anunciante
    require_auth_users
    raise AccessDenied unless @user.has_skill?("Advertiser")
    @advertisers = @user.users_skills.find(:all, :conditions => 'role = \'Advertiser\'')
    @advertisers_ids = [0] + @advertisers.collect { |adv| adv.role_data.to_i }
    # @advertisers_ids << 0] if @advertisers_ids.size == 0
    @active_sawmode = 'anunciante'
  end

  def hq
    require_auth_users
    raise AccessDenied unless @user.is_hq?
    @active_sawmode = 'hq'
  end
end
