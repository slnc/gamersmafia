module EncuestasHelper
  def live_polls
    # TODO(slnc): this returns all live polls right now, temp hack. Once we
    # merge Content and content-specific classes we just need to call
    # of_interest_to
    Poll.published.is_live.find(:all)
  end
end
