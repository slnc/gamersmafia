require "#{File.dirname(__FILE__)}/../test_helper"

class ContentsLinksTest < ActionController::IntegrationTest
  def setup
    ActionController::Base.perform_caching             = true
    host! App.domain
  end

  test "should_show_reportar_if_hq" do
    post '/cuenta/do_login', { :login => :panzer, :password => :lelele }
    host! "ut.#{App.domain}"

    get '/noticias/show/1'
    assert !response.body.include?('report-contents'), response.body

    host! "ut.#{App.domain}"
    User.find_by_login('panzer').update_attributes(:is_hq => true)
    get '/noticias/show/1'
    assert response.body.include?('report-contents')
  end
end
