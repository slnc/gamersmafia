# -*- encoding : utf-8 -*-
class ReclutamientoController < ApplicationController
  acts_as_content_browser :recruitment_ads

  def index
    if params[:search]
      @game = Game.find_by_id(params[:game_id].to_i)
      return if @game.nil?
      sql = "deleted = 'f'"
      sql << " AND game_id = #{params[:game_id].to_i}"
      sql << ((params[:type] == 'searching_clan') ? " AND clan_id IS NULL" : " AND clan_id IS NOT NULL")

      if params[:levels]
        levels_sql = '('
        levels_sql << params[:levels].collect { |lvl| "levels LIKE '%#{lvl}%'" if %w(low med high).include?(lvl)}.join(" OR ")
        levels_sql << ')'
      else
        levels_sql = nil
      end

      sql << " AND #{levels_sql}" if levels_sql

      @results = RecruitmentAd.find(:all, :conditions => sql, :order => 'created_on DESC', :limit => 50)
    end
  end

  def anuncio
    show
    render :action => 'show' unless performed?
  end

  def _before_create
    require_auth_users

    if params[:reclutsearching] == 'users' then
      raise AccessDenied unless Clan.find(params[:recruitment_ad][:clan_id]).user_is_clanleader(@user.id)
    else
      params[:recruitment_ad][:clan_id] = nil
    end
    true
  end
end
