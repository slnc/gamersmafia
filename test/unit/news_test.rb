require 'test_helper'

class NewsTest < ActiveSupport::TestCase
  test "should_properly_change_url" do
    @news = News.new(:title => 'foo flash-hack', :user_id => 1, :description => 'bar flash', :terms => Term.single_toplevel(:slug => 'ut').id)
    assert @news.save
    assert @news.unique_content.url.include?("http://ut.#{App.domain}/"), @news.unique_content.url
    assert Term.single_toplevel(:slug => 'ut').unlink(@news.unique_content)
    assert Term.single_toplevel(:slug => 'gm').link(@news.unique_content)
    assert @news.unique_content.url.include?("http://#{App.domain}/"), @news.unique_content.url
  end
  
  test "should_properly_change_set source if nil" do
    @news = News.new(:title => 'foo flash-hack', :user_id => 1, :description => 'bar flash', :terms => Term.single_toplevel(:slug => 'ut').id)
    assert @news.save
    assert_nil @news.source
    assert_nil @news.unique_content.source
  end
  
  test "should_properly_change_set source if invalid source" do
    @news = News.new(:title => 'foo flash-hack', :user_id => 1, :description => 'bar flash', :terms => Term.single_toplevel(:slug => 'ut').id, :source => 'source not nil')
    assert !@news.save
  end
  
  test "should_properly_change_set source if valid source" do
    @news = News.new(:title => 'foo flash-hack', :user_id => 1, :description => 'bar flash', :terms => Term.single_toplevel(:slug => 'ut').id, :source => 'http://google.com/')
    assert @news.save
    assert_equal @news.source, @news.unique_content.source
  end
  
  test "should_properly_change_set source if valid source first and then nil" do
    test_should_properly_change_set_source_if_valid_source
    assert @news.update_attributes(:source => nil)
    assert_nil @news.source
    assert_nil @news.unique_content.source
  end
end
