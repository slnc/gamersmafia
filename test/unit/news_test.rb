require File.dirname(__FILE__) + '/../test_helper'

class NewsTest < Test::Unit::TestCase

  def setup
    @news = News.find(1)
  end

  # Replace this with your real tests.
  def test_should_properly_change_url
    @news = News.new(:title => 'foo flash-hack', :user_id => 1, :description => 'bar flash', :news_category_id => 1)
    assert @news.save
    assert @news.unique_content.url.include?('http://ut.gamersmafia.dev/')
    assert @news.update_attributes(:news_category_id => 4)
    assert @news.unique_content.url.include?('http://gamersmafia.dev/'), @news.unique_content.url
  end
  
  def test_should_move_sent_to_bazar_to_inet
    @news = News.find(:first)
    assert @news.update_attributes(:news_category_id => NewsCategory.find_by_code('bazar').id)
    assert_equal NewsCategory.find_by_code('inet').id, @news.news_category_id
  end
end
