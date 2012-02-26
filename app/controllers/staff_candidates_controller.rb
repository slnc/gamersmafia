class StaffCandidatesController < ApplicationController
  def index
    @staff_position = StaffPosition.find_or_404(
      params[:staff_position_id], :include => :staff_type)
  end

  def show
    @staff_candidate = StaffCandidate.find_or_404(
      params[:id])
  end

  def new
    @staff_position = StaffPosition.find_or_404(
      params[:staff_position_id], :include => :staff_type)

    @staff_candidate = @staff_position.staff_candidates.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @post }
    end
  end

  def create

  end

  #protected
  #def require_can_present_himself
  #  reasons = @staff_position.user_is_candidate(@user)

  #  end
  #end
end
