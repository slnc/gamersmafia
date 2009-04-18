require "#{File.dirname(__FILE__)}/../test_helper"

class CommentsPerformanceTest < ActionController::IntegrationTest
  def setup
    ActionController::Base.perform_caching             = true
    host! "#{App.domain}"
  end
  
  test "speed" do
    old = Comment.count
    sym_login :superadmin, :lalala
    10.times do |i|
      puts i
      post "/comments/create/", { :comment => { :content_id => 1, :comment => "hola[#{i}" }, :redirto => '/'}
      assert_response :redirect, @response.body
    end
    assert_equal old + 10, Comment.count 
  end
end
