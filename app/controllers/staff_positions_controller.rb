class StaffPositionsController < ApplicationController
  def index
    @title = "Staff"
  end

  def show
    @staff_position = StaffPosition.find_or_404(
      params[:id], :include => :staff_type)
    @title = "Staff &raquo; #{@staff_position.staff_type.name}"
  end
end
