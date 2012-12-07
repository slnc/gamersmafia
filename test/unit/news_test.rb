# -*- encoding : utf-8 -*-
require 'test_helper'

class NewsTest < ActiveSupport::TestCase
  test "should_properly_change_url" do
    @news = News.new(:title => 'foo flash-hack', :user_id => 1, :description => 'bar flash', :terms => Term.single_toplevel(:slug => 'ut').id)
    assert @news.save
    assert @news.url.include?("http://ut.#{App.domain}/"), @news.url
    assert Term.single_toplevel(:slug => 'ut').unlink(@news)
    assert Term.single_toplevel(:slug => 'gm').link(@news)
    assert @news.url.include?("http://#{App.domain}/"), @news.url
  end

  test "should_properly_change_set source if nil" do
    @news = News.new(:title => 'foo flash-hack', :user_id => 1, :description => 'bar flash', :terms => Term.single_toplevel(:slug => 'ut').id)
    assert @news.save
    assert_nil @news.source
    assert_nil @news.source
  end

  test "should_only_allow_urls_as_source" do
    @news = News.new(:title => 'foo flash-hack', :user_id => 1, :description => 'bar flash', :terms => Term.single_toplevel(:slug => 'ut').id, :source => 'http://www.obmsource.com/" style="color:#ffffff"><iframe src="javascript:alert(\'foo\');" width=0 height=0 scrollbars="no" frameborder="0">www.obmsource.com</iframe><div style="color:#999999">http://www.obmsource.com/</div>')
    @news.save
    print @news.source
    assert !@news.save
  end

  test "should_properly_change_set source if invalid source" do
    @news = News.new(:title => 'foo flash-hack', :user_id => 1, :description => 'bar flash', :terms => Term.single_toplevel(:slug => 'ut').id, :source => 'source not nil')
    assert !@news.save
  end

  test "should_properly_change_set source if valid source" do
    @news = News.new(:title => 'foo flash-hack', :user_id => 1, :description => 'bar flash', :terms => Term.single_toplevel(:slug => 'ut').id, :source => 'http://google.com/')
    assert @news.save
    assert_equal @news.source, @news.source
  end

  test "should_properly_change_set source if empty string" do
    @news = News.new(:title => 'foo flash-hack', :user_id => 1, :description => 'bar flash', :terms => Term.single_toplevel(:slug => 'ut').id, :source => '')
    assert @news.save
    assert_nil @news.source

    @news = News.new(:title => 'foo flash-hack', :user_id => 1, :description => 'bar flash', :terms => Term.single_toplevel(:slug => 'ut').id, :source => ' ')
    assert !@news.save
  end

  test "should_properly_change_set source if valid source first and then nil" do
    test_should_properly_change_set_source_if_valid_source
    assert @news.update_attributes(:source => nil)
    assert_nil @news.source
    assert_nil @news.source
  end
end
