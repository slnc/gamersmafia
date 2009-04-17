require 'test_helper'

class NewsTest < ActiveSupport::TestCase
  test "should_properly_change_url" do
    @news = News.new(:title => 'foo flash-hack', :user_id => 1, :description => 'bar flash', :terms => Term.single_toplevel(:slug => 'ut').id)
    assert @news.save
    assert @news.unique_content.url.include?('http://ut.gamersmafia.dev/'), @news.unique_content.url
    assert Term.single_toplevel(:slug => 'ut').unlink(@news.unique_content)
    assert Term.single_toplevel(:slug => 'gm').link(@news.unique_content)
    assert @news.unique_content.url.include?('http://gamersmafia.dev/'), @news.unique_content.url
  end
end
