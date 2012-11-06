class DecisionCommentsController < ApplicationController

  def create
    @decision = Decision.find(params[:decision_id].to_i)
    require_authorization_for_object(:can_comment_on_decision?, @decision)
    @decision.decision_comments.create({
        :comment => params[:comment],
        :user_id => @user.id
    })
    # TODO(slnc): show errors if any
    render :action => :index, :layout => false
  end

  def index
    @decision = Decision.find(params[:decision_id].to_i)
  end
end
