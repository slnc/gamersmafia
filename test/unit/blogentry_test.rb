# -*- encoding : utf-8 -*-
require 'test_helper'

class BlogentryTest < ActiveSupport::TestCase

  test "url_should_be_reset_when_user_changes_login" do
    be = Blogentry.find(:first, :include => :user)
    assert be.url.include?(be.user.login)
    new_login = be.user.login.reverse
    be.reload
    assert be.user.update_attributes(:login => new_login)
    assert be.url.include?(new_login)
  end

end
