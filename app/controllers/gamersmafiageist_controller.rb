class GamersmafiageistController < ApplicationController
  before_filter :require_auth_users

  def index
  end

  def edicion
    if !@user.settled?
      flash[:error] = "No llevas en Gamersmafia suficiente tiempo como para participar en esta edici√n de la Gamersmafiageist, lo sentimos"
    else
      @code = GamersmafiageistCode.find(:first,
        :conditions => ['user_id = ? AND survey_edition_date = ?', @user.id,
        params[:survey_edition_date]])

      if not @code
        @code = GamersmafiageistCode.create(:user_id => @user.id,
        :survey_edition_date => params[:survey_edition_date])
        if @code.new_record?
          flash[:error] = "Imposible obtener c√≥digo para la encuest: #{@code.errors.full_messages_html}."
          @code = nil
        else
        end
      end
    end
  end
end
