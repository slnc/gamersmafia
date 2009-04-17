require 'test_helper'

class BlogentryTest < ActiveSupport::TestCase
  # TODO model checks
  def setup
    
  end

  test "url_should_be_reset_when_user_changes_login" do
    be = Blogentry.find(:first, :include => :user)
    assert be.unique_content.url.include?(be.user.login)
    new_login = be.user.login.reverse
    be.reload
    assert be.user.update_attributes(:login => new_login)
    assert be.unique_content.url.include?(new_login)
  end
end
