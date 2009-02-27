require File.dirname(__FILE__) + '/../test_helper'

class NewsTest < Test::Unit::TestCase
  def test_should_properly_change_url
    @news = News.new(:title => 'foo flash-hack', :user_id => 1, :description => 'bar flash', :news_category_id => 1)
    assert @news.save
    assert Term.single_toplevel(:slug => 'ut').link(@news.unique_content)
    assert @news.unique_content.url.include?('http://ut.gamersmafia.dev/')
    assert Term.single_toplevel(:slug => 'ut').unlink(@news)
    assert Term.single_toplevel(:slug => 'gm').link(@news.unique_content)
    assert @news.unique_content.url.include?('http://gamersmafia.dev/'), @news.unique_content.url
  end
end
