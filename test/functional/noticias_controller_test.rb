require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../test_functional_content_helper'
require 'noticias_controller'

class NoticiasController; def rescue_action(e) raise e end; end

class NoticiasControllerTest < Test::Unit::TestCase
  test_common_content_crud :name => 'News', :form_vars => {:title => 'footapang', :description => 'bartapang', :terms => 1} # :authed_user_id => 11, :non_authed_user_id => 1000
  
  def setup
    @controller = NoticiasController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  def test_update_should_save_contents_version
    sym_login 1
    n = News.find(1)
    prev_attrs = n.attributes
    
    assert_count_increases(ContentsVersion) do
      post :update, :id => 1, :news => { :title => "cachan chan", :description => "description NN", :main => "main NN"} 
      assert_response :redirect
    end
    n.reload
    cv = ContentsVersion.find(:first, :order => 'id DESC')
    %w(title main description).each do |attr|
      assert_not_equal cv.data[attr], n.send(attr)
      assert_not_equal prev_attrs[attr], n.send(attr)
      assert_equal prev_attrs[attr], cv.data[attr]
    end
  end
  
  def test_index_should_work_in_portal
    setup_clan_skin
    cp = ClansPortal.find(:first)
    @request.host = "#{cp.code}.#{App.domain}"
    get :index
    assert @controller.portal.kind_of?(ClansPortal), @controller.portal.class.name
    assert_response :success
  end
  
  def test_news_should_work_in_portal
    setup_clan_skin
    cp = ClansPortal.find(:first)
    @request.host = "#{cp.code}.#{App.domain}"
    get :show, :id => News.find(:published, :conditions => "news_category_id IN (SELECT id FROM news_categories WHERE clan_id = #{cp.clan.id} AND id = root_id)", :limit => 1)[0].id
    assert @controller.portal.kind_of?(ClansPortal), @controller.portal.class.name
    assert_response :success
  end
  
  def test_second_level_categories_should_work
    get :second_level_categories, {:id => Term.find(1)}
    assert_response :success
  end
  
  def test_create_without_subcat_should_work
    sym_login 1
    assert_count_increases(News) do 
      post :create, { :news => {:title => 'footapang', :description => 'bartapang', :terms => 1}, :secondlevel_news_category_id => '', :new_subcategory_name => '' }
    end
    assert_equal 1, News.find(:first, :order => 'id desc').news_category_id
  end
  
  def atest_create_with_existing_subcategory_should_work
    sym_login 1
    nc = NewsCategory.find(1).children.create({:name => 'soy de second level'})
    assert_not_nil nc.id
    assert_count_increases(News) do 
      post :create, { :news => {:title => 'footapang', :description => 'bartapang', :terms => 1}, :second_level_news_category_id => nc.id, :new_subcategory_name => '' }
    end
    assert_equal nc.id, News.find(:first, :order => 'id desc').news_category_id
  end
  
  def atest_create_with_new_subcategory_without_image_should_create_subcategory
    sym_login 1
    assert_count_increases(NewsCategory) do
      assert_count_increases(News) do 
        post :create, { :news => {:title => 'footapang', :description => 'bartapang', :terms => 1}, :new_subcategory_name => 'blah' }
      end
    end
    n = News.find(:first, :order => 'id desc')
    assert_equal 'blah', n.news_category.name
    assert_equal 1, n.news_category.parent_id
    assert_equal 1, n.news_category.root_id
    assert_response :redirect
  end
  
  def atest_create_with_new_subcategory_with_image_should_create_subcategory_and_image
    sym_login 1
    assert_count_increases(NewsCategory) do
      assert_count_increases(News) do 
        post :create, { :news => {:title => 'footapang', :description => 'bartapang', :terms => 1}, :new_subcategory_name => 'blah', :new_subcategory_file => fixture_file_upload('/files/buddha.jpg', 'image/jpeg') }
      end
    end
    n = News.find(:first, :order => 'id desc')
    assert_nil flash[:error], flash[:error]
    assert_equal 'blah', n.news_category.name
    assert_equal 1, n.news_category.parent_id
    assert_equal 1, n.news_category.root_id
    assert n.news_category.file.include?('buddha.jpg')
    assert_response :redirect
  end
end
