# -*- encoding : utf-8 -*-
class GamersmafiageistController < ApplicationController
  before_filter :require_auth_users

  def index
  end

  def edicion
  flash[:error] = "La encuesta est&aacute; cerrada."
  return
    if !@user.settled?
      flash[:error] = "No llegas en Gamersmafia suficiente tiempo como para participar en esta edición de la Gamersmafiageist, lo sentimos"
    else
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
