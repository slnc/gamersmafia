class StaffPositionsController < ApplicationController

  def index
    @title = "Staff"
  end

  def show
    @staff_position = StaffPosition.find_or_404(
      params[:id], :include => :staff_type)
    @title = "Staff &raquo; #{@staff_position.staff_type.name}"
  end

  def move_to_candidacy_presentation
    require_auth_users
    require_admin_permission :capo
    @staff_position = StaffPosition.find_or_404(
      params[:id], :include => :staff_type)
    @staff_position.open_candidacy_presentation
    if @staff_position.save
      #flash[:notice] = "Posición movida a candidaturas abiertas."
    else
      flash[:error] = (
          "Error al mover posición: " +
          " #{@staff_position.errors.full_messages_html}.")
    end
    # redirect_to staff_position_path(@staff_position)
    render :nothing => true
  end
end
