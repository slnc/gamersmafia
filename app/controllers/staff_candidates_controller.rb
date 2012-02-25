class StaffCandidatesController < ApplicationController
  def index
    @staff_position = StaffPosition.find_or_404(
      params[:id], :include => :staff_type)
  end

  def show
    @staff_candidate = StaffCandidate.find_or_404(
      params[:id])
  end
end
