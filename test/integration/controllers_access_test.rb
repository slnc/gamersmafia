require "test_helper"

class ControllersAccessTest < ActionController::IntegrationTest
  test "test_app_config" do
    assert_not_nil App.domain
  end
end
