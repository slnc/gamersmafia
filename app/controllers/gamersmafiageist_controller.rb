# -*- encoding : utf-8 -*-
class GamersmafiageistController < ApplicationController
  before_filter :require_auth_users

  def index
  end

  EDITION_URL = {
    "2011" => "https://docs.google.com/a/slnc.me/spreadsheet/viewform?hl=en_US&formkey=dDFMT0xSSkM5Y0FKUm5NUWpIRDJOWWc6MQ#gid=0",
    "2012" =>  "https://docs.google.com/spreadsheet/viewform?formkey=dDVsSDJkVkM4V0xGWUVWdGtSbHpUbmc6MA",
  }

  def edicion
    if params[:survey_edition_date] != '2012'
      raise ActiveRecord::RecordNotFound
    end

    if !@user.settled?
      flash[:error] = (
        "No llegas en Gamersmafia suficiente tiempo como para participar en
        esta edición de la Gamersmafiageist, lo sentimos")
    else
      @edition_url = EDITION_URL.fetch(params[:survey_edition_date])
      @code = GamersmafiageistCode.find(:first,
        :conditions => ['user_id = ? AND survey_edition_date = ?', @user.id,
        params[:survey_edition_date]])

      if not @code
        @code = GamersmafiageistCode.create(:user_id => @user.id,
        :survey_edition_date => params[:survey_edition_date])
        if @code.new_record?
          flash[:error] = "Imposible obtener código para la encuest: #{@code.errors.full_messages_html}."
          @code = nil
        else
        end
      end
    end
  end
end
