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
    else
      flash[:error] = (
          "Error al mover posición: " +
          " #{@staff_position.errors.full_messages_html}.")
    end
    render :nothing => true
  end

  def confirm_winners
    require_auth_users
    @staff_position = StaffPosition.find_or_404(params[:id])
    if !Staff.can_confirm_staff_position_winners(@user, @staff_position)
      raise AccessDenied
    end
    @staff_position.confirm_winners
    render :action => "show"
  end
end
