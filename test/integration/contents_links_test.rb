# -*- encoding : utf-8 -*-
require "test_helper"

class ContentsLinksTest < ActionController::IntegrationTest
  def setup
    ActionController::Base.perform_caching             = true
    host! App.domain
  end

  test "should_show_reportar_if_skill" do
    post '/cuenta/do_login', { :login => :panzer, :password => :lelele }
    host! "ut.#{App.domain}"

    get '/noticias/show/1'
    assert !response.body.include?('report-contents'), response.body

    host! "ut.#{App.domain}"
    assert User.find_by_login('panzer').users_skills.create(
        :role => "ReportContents")
    get '/noticias/show/1'
    assert response.body.include?('report-contents'), response.body
  end
end
