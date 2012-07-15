# -*- encoding : utf-8 -*-
require 'test_helper'

class ApplicationControllerIntegrationTest < ActionController::IntegrationTest
  test "content locked" do
    n66 = News.published.find(66)
    out = n66.lock(User.find(2))

    sym_login 'superadmin', 'lalala'

    assert_raises(ContentLocked::ContentLocked) { get("/noticias/edit/66") }
  end
end
