require 'test_helper'


class RefererHitTest < ActionController::IntegrationTest
  def setup
    host! App.domain
  end

  test "should_give_faith_points_if_refered_link" do
    u1 = User.find(1)
    points = u1.faith_points
    get '/?rusid=1'
    assert_response :success, @response.body
    u1.reload
    assert_equal points + Faith::FPS_ACTIONS['hit'], u1.faith_points
  end
end
