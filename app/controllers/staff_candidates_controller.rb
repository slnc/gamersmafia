# -*- encoding : utf-8 -*-
class StaffCandidatesController < ApplicationController
  def index
    @staff_position = StaffPosition.find_or_404(
      params[:staff_position_id], :include => :staff_type)
  end

  def show
    @staff_position = StaffPosition.find_or_404(
      params[:staff_position_id], :include => :staff_type)

    @staff_candidate = StaffCandidate.find_or_404(
      params[:id])
  end

  def new
    @staff_position = StaffPosition.find_or_404(
      params[:staff_position_id], :include => :staff_type)

    @staff_candidate = @staff_position.staff_candidates.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def create
    @staff_position = StaffPosition.find_or_404(
      params[:staff_position_id], :include => :staff_type)

    @staff_candidate = @staff_position.staff_candidates.new(params[:staff_candidate])
    @staff_candidate.user_id = @user.id

    if @staff_candidate.save
      redirect_to(staff_position_staff_candidate_path(@staff_position, @staff_candidate),
                  :notice => 'Candidatura creada correctamente.')
    else
      render :action => "new"
    end
  end

  def delete
    @staff_position = StaffPosition.find_or_404(
      params[:staff_position_id], :include => :staff_type)

    @staff_candidate = StaffCandidate.find(:first,
        :conditions => ['id = ? AND user_id = ?', params[:id], @user.id])

    @staff_candidate.destroy
      redirect_to(staff_position_path(@staff_position),
                  :notice => 'Candidatura eliminada correctamente.')
  end

  def vote
    @staff_position = StaffPosition.find_or_404(
      params[:staff_position_id], :include => :staff_type)

    @staff_candidate = StaffCandidate.find_or_404(
      params[:id])

    if !Staff.user_can_vote_staff_candidate(@user, @staff_candidate)
      raise AccessDenied
    end

    new_vote = @staff_position.update_user_vote(@user, @staff_candidate)
    if new_vote.new_record?
      feedback = {:error => new_vote.errors.full_messages_html}
    else
      feedback = {:notice => "Voto registrado correctamente."}
    end
    redirect_to(
      staff_position_staff_candidate_path(@staff_position, @staff_candidate),
      feedback)
  end

  def deny
    @staff_position = StaffPosition.find_or_404(
      params[:staff_position_id], :include => :staff_type)

    @staff_candidate = StaffCandidate.find_or_404(
      params[:id])

    if !Staff.user_can_deny_staff_candidate(@user, @staff_candidate)
      raise AccessDenied
    end

    if @staff_position.update_attributes(:is_denied => true)
      feedback = {:notice => "Posición denegada correctamente."}
    else
      feedback = {:error => "Error al denegar posición:" +
                  " #{@staff_position.errors.full_messages_html}"}
    end
    redirect_to(
      staff_position_staff_candidate_path(@staff_position, @staff_candidate),
      feedback)
  end
end
